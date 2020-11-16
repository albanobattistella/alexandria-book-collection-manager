# frozen_string_literal: true

# This file is part of Alexandria.
#
# See the file README.md for authorship and licensing information.

require_relative "../../spec_helper"

describe Alexandria::UI::SkipEntryDialog do
  let(:parent) { Gtk::Window.new :toplevel }

  it "works" do
    described_class.new parent, "Foo"
  end

  describe "continue?" do
    let(:instance) { described_class.new parent, "Foo" }
    let(:dialog) { instance.dialog }

    it "works when response is cancel" do
      allow(dialog).to receive(:run).and_return(Gtk::ResponseType::CANCEL)
      expect(instance.continue?).to be_falsey
    end

    it "works when response is OK" do
      allow(dialog).to receive(:run).and_return(Gtk::ResponseType::OK)
      expect(instance.continue?).to be_truthy
    end
  end
end
