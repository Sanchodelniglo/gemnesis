# frozen_string_literal: true

require "gemnesis/cleaner"
require "stringio"
require "tmpdir"

RSpec.describe Gemnesis::Cleaner do
  let(:io) { StringIO.new }

  around do |example|
    Dir.mktmpdir("gemnesis-clean-") do |dir|
      @tmp = dir
      File.write(File.join(dir, "gemnesis.rb"), "# placeholder")
      example.run
    end
  end

  def cleaner = described_class.new(project_dir: @tmp, io: io)

  describe "#run" do
    it "removes build artifacts and reports each one" do
      FileUtils.mkdir_p(File.join(@tmp, "out"))
      File.write(File.join(@tmp, "out", "rom.bin"), "x")
      FileUtils.mkdir_p(File.join(@tmp, "src"))
      File.write(File.join(@tmp, "src", "config.h"), "x")
      File.write(File.join(@tmp, "src", "main.o"), "x")

      expect(cleaner.run).to eq(0)
      expect(File).not_to exist(File.join(@tmp, "out"))
      expect(File).not_to exist(File.join(@tmp, "src", "config.h"))
      expect(File).not_to exist(File.join(@tmp, "src", "main.o"))
      expect(io.string).to include("out", "config.h", "main.o")
    end

    it "reports 'Already clean.' when nothing to remove" do
      expect(cleaner.run).to eq(0)
      expect(io.string.strip).to eq("Already clean.")
    end

    it "refuses to run outside a gemnesis project" do
      File.delete(File.join(@tmp, "gemnesis.rb"))
      expect { cleaner.run }.to raise_error(Gemnesis::Error, /no gemnesis.rb/)
    end
  end
end
