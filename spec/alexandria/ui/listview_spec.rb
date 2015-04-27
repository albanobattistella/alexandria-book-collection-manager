# Copyright (C) 2008 Joseph Method
# Copyright (C) 2014 Matijs van Zuijlen
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

require File.dirname(__FILE__) + '/../../spec_helper'

describe Alexandria::UI::ListViewManager do
  it 'should work' do
    listview = double(Gtk::TreeView).as_null_object
    parent = double(Object, listview: listview).as_null_object
    expect(listview).to receive(:enable_model_drag_source)
    Alexandria::UI::ListViewManager.new(listview, parent)
  end
end
