# frozen_string_literal: true

# This file is part of Alexandria.
#
# See the file README.md for authorship and licensing information.

require_relative "../../spec_helper"

describe Alexandria::UI::ConfirmEraseDialog do
  it "works" do
    parent = Gtk::Window.new :toplevel
    described_class.new parent, "foo-file"
  end
end
