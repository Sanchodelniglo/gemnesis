# frozen_string_literal: true

# Real-Docker integration: scaffolds a project, runs `gemnesis build`,
# asserts a valid ROM lands at out/rom.bin. Skipped unless
# GEMNESIS_INTEGRATION=1 is set (Docker pull is slow, CI gates this).

require "gemnesis/scaffolder"
require "gemnesis/builder"
require "stringio"
require "tmpdir"

RSpec.describe "gemnesis build (real Docker)", :integration do
  before do
    skip "set GEMNESIS_INTEGRATION=1 to enable" unless ENV["GEMNESIS_INTEGRATION"] == "1"
  end

  it "scaffolds a project and produces a non-empty ROM" do
    Dir.mktmpdir("gemnesis-int-") do |dir|
      Gemnesis::Scaffolder.new("demo", base_dir: dir, io: StringIO.new).run
      project = File.join(dir, "demo")

      io = StringIO.new
      builder = Gemnesis::Builder.new(project_dir: project, io: io, verbose: true)
      expect(builder.run).to eq(0)

      rom = File.join(project, "out", "rom.bin")
      expect(File).to exist(rom)
      expect(File.size(rom)).to be > 0

      # Mega Drive ROM header magic at offset 0x100 = "SEGA"
      File.open(rom, "rb") do |f|
        f.seek(0x100)
        expect(f.read(4)).to eq("SEGA")
      end
    end
  end
end
