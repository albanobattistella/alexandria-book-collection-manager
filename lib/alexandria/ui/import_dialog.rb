# Copyright (C) 2004-2006 Laurent Sansonetti
#
# Alexandria is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# Alexandria is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public
# License along with Alexandria; see the file COPYING.  If not,
# write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA.

require 'thread'
require 'logger'

class Alexandria::ImportFilter
    def to_filefilter
        filefilter = Gtk::FileFilter.new
        filefilter.name = name
        patterns.each { |x| filefilter.add_pattern(x) }
        return filefilter
    end
end

module Alexandria
module UI
    class SkipEntryDialog < AlertDialog
        include GetText
        GetText.bindtextdomain(Alexandria::TEXTDOMAIN, nil, nil, "UTF-8")
        
        def initialize(parent, message)
        	@logger = Logger.new(STDOUT)
            super(parent, _("Error while importing"),
                  Gtk::Stock::DIALOG_QUESTION,
                  [[Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
                   [_("_Continue"), Gtk::Dialog::RESPONSE_OK]], 
                  message)
            @logger.info("Opened SkipEntryDialog #{self.inspect}")
            self.default_response = Gtk::Dialog::RESPONSE_CANCEL
            show_all and @response = run
            destroy
        end

        def continue?
            @response == Gtk::Dialog::RESPONSE_OK
        end
    end

    class ImportDialog < Gtk::FileChooserDialog
        include GetText
        GetText.bindtextdomain(Alexandria::TEXTDOMAIN, nil, nil, "UTF-8")
    
        FILTERS = Alexandria::ImportFilter.all

        def initialize(parent, &on_accept_cb)
            super()
            @logger = Logger.new(STDOUT)
            @logger.info("ImportDialog opened.")
            self.title = _("Import a Library") 
            self.action = Gtk::FileChooser::ACTION_OPEN
            self.transient_for = parent
#            self.deletable = false
            running = false
            add_button(Gtk::Stock::HELP, Gtk::Dialog::RESPONSE_HELP) 
            add_button(Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL)
            import_button = add_button(_("_Import"), 
                                       Gtk::Dialog::RESPONSE_ACCEPT)
            import_button.sensitive = false
                 
            self.signal_connect('destroy') { self.destroy unless running }

            filters = {}
            FILTERS.each do |filter|
                filefilter = filter.to_filefilter
                self.add_filter(filefilter)
                @logger.debug("Added ImportFilter #{filefilter} -- #{filefilter.name}")
                filters[filefilter] = filter
            end

            self.signal_connect('selection_changed') do
                import_button.sensitive = 
                    self.filename and File.file?(self.filename)
            end

            # before adding the (hidden) progress bar, we must re-set the
            # packing of the button box (currently packed at the end), 
            # because the progressbar will be *after* the button box.
            buttonbox = self.vbox.children.last
            options = self.vbox.query_child_packing(buttonbox)
            options[-1] = Gtk::PACK_START
            self.vbox.set_child_packing(buttonbox, *options)
            self.vbox.reorder_child(buttonbox, 1)

            pbar = Gtk::ProgressBar.new
            pbar.show_text = true
            self.vbox.pack_start(pbar, false)

            on_progress = proc do |fraction|
                pbar.show unless pbar.visible?
                pbar.fraction = fraction
            end

            on_error = proc do |message|
                SkipEntryDialog.new(parent, message).continue?
            end
           
            exec_queue = ExecutionQueue.new
           
            while (response = run) != Gtk::Dialog::RESPONSE_CANCEL and
                  response != Gtk::Dialog::RESPONSE_DELETE_EVENT

                if response == Gtk::Dialog::RESPONSE_HELP
                    begin
                        Gnome::Help.display('alexandria', 'import-library')
                    rescue => e 
                        ErrorDialog.new(self, e.message)
                    end
                    next
                end
                file = File.basename(self.filename, '.*')
                base = GLib.locale_to_utf8(file)
                new_library_name = Library.generate_new_name(
                    Libraries.instance.all_libraries, 
                    base)

                filter = filters[self.filter]
                puts "Going forward with filter: #{filter.name}"
                self.sensitive = false 
                
                filter.on_iterate do |n, total|
                    # convert to percents
                    coeff = total / 100.0
                    percent = n / coeff
                    # fraction between 0 and 1
                    fraction = percent / 100 
                    @logger.debug("#{self.inspect} Percentage: #{fraction}")
                    exec_queue.call(on_progress, fraction)
                end

                not_cancelled = true 
                filter.on_error do |message|
                    not_cancelled = exec_queue.sync_call(on_error, message)
                    @logger.debug("#{self.inspect} cancel state: #{not_cancelled}")
                end

                library = nil
                @bad_isbns = nil
                thread = Thread.start do
                    library, @bad_isbns = filter.invoke(new_library_name, 
                                            self.filename)
                end
                
                while thread.alive?
                	#puts "Thread #{thread} still alive."
                	running = true
                    exec_queue.iterate
                    Gtk.main_iteration_do(false) 
                end
               
                if library
                    on_accept_cb.call(library, @bad_isbns)
                    break
                elsif not_cancelled
                	@logger.debug("Raising ErrorDialog because not_cancelled is #{not_cancelled}")
                    ErrorDialog.new(parent, 
                                    _("Couldn't import the library"),
                                    _("The format of the file you " +
                                      "provided is unknown.  Please " +
                                      "retry with another file."))
                end
                pbar.hide
                self.sensitive = true
            end
            destroy
        end
    end
end
end
