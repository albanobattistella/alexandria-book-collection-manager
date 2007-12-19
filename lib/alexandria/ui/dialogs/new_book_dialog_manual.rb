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
# write to the Free Software Foundation, Inc., 51 Franklin Street,
# Fifth Floor, Boston, MA 02110-1301 USA.

module Alexandria
  module UI
    class NewBookDialogManual < BookPropertiesDialogBase
      include GetText
      extend GetText
      GetText.bindtextdomain(Alexandria::TEXTDOMAIN, nil, nil, "UTF-8")

      TMP_COVER_FILE = File.join(Dir.tmpdir, "tmp_cover")
      def initialize(parent, library, &on_add_cb)
        super(parent, TMP_COVER_FILE)

        @library, @on_add_cb = library, on_add_cb
        FileUtils.rm_f(TMP_COVER_FILE)

        cancel_button = Gtk::Button.new(Gtk::Stock::CANCEL)
        cancel_button.signal_connect('clicked') { on_cancel }
        cancel_button.show
        @button_box << cancel_button

        add_button = Gtk::Button.new(Gtk::Stock::ADD)
        add_button.signal_connect('clicked') { on_add }
        add_button.show
        @button_box << add_button

        help_button = Gtk::Button.new(Gtk::Stock::HELP)
        help_button.signal_connect('clicked') { on_help }
        help_button.show
        @button_box << help_button
        @button_box.set_child_secondary(help_button, true)

        self.rating = Book::DEFAULT_RATING
        self.cover = Icons::BOOK_ICON

        on_title_changed
      end

      def on_title_changed
        title = @entry_title.text.strip
        begin
          @book_properties_dialog.title = unless title.empty?
                                            _("Adding '%s'") % title
                                          else
                                            _("Adding a Book")
                                          end
        rescue
          raise "There's a problem with a book somewhere"
        end
      end

      #######
      private
      #######

      def on_cancel
        @book_properties_dialog.destroy
      end

      class AddError < StandardError
      end

      def on_add
        begin
          if (title = @entry_title.text.strip).empty?
            raise AddError.new(_("A title must be provided."))
          end

          isbn = nil
          if @entry_isbn.text != ""
            ary = @library.select { |book| book.ident ==
              @entry_isbn.text }
            raise AddError.new(_("The EAN/ISBN you provided is " +
                                 "already used in this library.")) \
            unless ary.empty?
              isbn = begin
                       Library.canonicalise_isbn(@entry_isbn.text)
                     rescue Alexandria::Library::InvalidISBNError
                       raise AddError.new(_("Couldn't validate the " +
                                            "EAN/ISBN you provided.  Make " +
                                            "sure it is written correcty, " +
                                            "and try again."))
                     end
            end

            if (publisher = @entry_publisher.text.strip).empty?
              raise AddError.new(_("A publisher must be provided."))
            end

            publishing_year = @entry_publish_date.text.to_i

            if (edition = @entry_edition.text.strip).empty?
              raise AddError.new(_("A binding must be provided."))
            end

            authors = []
            @treeview_authors.model.each { |m, p, i| authors << i[0] }
            if authors.empty?
              raise AddError.new(_("At least one author must be " +
                                   "provided."))
            end

            book = Book.new(title, authors, isbn, publisher,
                            publishing_year == 0 ? nil : publishing_year,
                            edition)
            book.rating = @current_rating
            book.notes = @textview_notes.buffer.text
            book.loaned = @checkbutton_loaned.active?
            book.loaned_to = @entry_loaned_to.text
            book.loaned_since = Time.at(@date_loaned_since.time)

            @library << book
            @library.save(book)
            if File.exists?(TMP_COVER_FILE)
              FileUtils.cp(TMP_COVER_FILE, @library.cover(book))
            end

            @on_add_cb.call(book)
            @book_properties_dialog.destroy
          rescue AddError => e
            ErrorDialog.new(@parent, _("Couldn't add the book"),
                            e.message)
          end
        end

        def on_help
          Alexandria::UI::display_help(@preferences_dialog, 'add-book-manually')
        end
      end
    end
  end

