# frozen_string_literal: true

require "gemnesis/config"
require "gemnesis/rom_header"

RSpec.describe Gemnesis::RomHeader do
  def config(title:, region: :ntsc, author: "Me")
    cfg = Gemnesis::Config.new
    cfg.title = title
    cfg.region = region
    cfg.author = author
    cfg
  end

  describe "#to_c" do
    it "puts the validated title in both domestic and international slots, padded to 48" do
      out = described_class.new(config(title: "Hero Quest")).to_c

      padded = "Hero Quest".ljust(48)
      expect(out.scan(/"#{Regexp.escape(padded)}"/).count).to eq(2)
    end

    it "renders copyright as (C)<author> padded to 16 chars" do
      out = described_class.new(config(title: "x", author: "Alice")).to_c
      expect(out).to include(%("#{"(C)Alice".ljust(16)}"))
    end

    it "maps :ntsc to U, :pal to E, :both to JUE" do
      ntsc = described_class.new(config(title: "x", region: :ntsc)).to_c
      pal  = described_class.new(config(title: "x", region: :pal)).to_c
      both = described_class.new(config(title: "x", region: :both)).to_c

      expect(ntsc).to include('"U               "')
      expect(pal).to  include('"E               "')
      expect(both).to include('"JUE             "')
    end

    it "escapes embedded quotes and backslashes" do
      out = described_class.new(config(title: 'He said "hi"')).to_c
      expect(out).to include('He said \\"hi\\"')
    end

    it "truncates titles that exceed 48 chars (defense in depth past Config validation)" do
      long = "x" * 60
      out = described_class.new(config(title: long)).to_c
      expect(out).to include(%("#{"x" * 48}"))
      expect(out).not_to include(%("#{"x" * 49}"))
    end
  end
end
