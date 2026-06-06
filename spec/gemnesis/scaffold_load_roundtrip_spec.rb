# frozen_string_literal: true

require "gemnesis/scaffolder"
require "gemnesis/config"
require "stringio"
require "tmpdir"

# End-to-end check: a freshly scaffolded gemnesis.rb must parse cleanly
# via Config.load_file. Catches placeholder/syntax drift in the template
# without needing real Docker.
RSpec.describe "Scaffolder → Config round-trip" do
  it "produces a gemnesis.rb that Config.load_file accepts (default attrs)" do
    Dir.mktmpdir("gemnesis-roundtrip-") do |dir|
      Gemnesis::Scaffolder.new("portal-gun", base_dir: dir, io: StringIO.new).run
      cfg = Gemnesis::Config.load_file(File.join(dir, "portal-gun", "gemnesis.rb"))
      expect(cfg.title).to eq("Portal Gun")
      expect(cfg.region).to eq(:ntsc)
      expect(cfg.author).to eq("You")
    end
  end

  it "produces a gemnesis.rb that Config.load_file accepts (custom attrs)" do
    Dir.mktmpdir("gemnesis-roundtrip-") do |dir|
      Gemnesis::Scaffolder.new(
        "mortys-adventure",
        attrs: { title: "Morty's Adventure", author: "Rick", region: "both" },
        base_dir: dir, io: StringIO.new
      ).run
      cfg = Gemnesis::Config.load_file(File.join(dir, "mortys-adventure", "gemnesis.rb"))
      expect(cfg.title).to eq("Morty's Adventure")
      expect(cfg.region).to eq(:both)
      expect(cfg.author).to eq("Rick")
    end
  end
end
