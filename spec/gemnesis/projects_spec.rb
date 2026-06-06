# frozen_string_literal: true

require "gemnesis/projects"
require "stringio"
require "tmpdir"

RSpec.describe Gemnesis::Projects do
  let(:io) { StringIO.new }

  around do |example|
    Dir.mktmpdir("gemnesis-proj-") do |dir|
      @tmp = dir
      example.run
    end
  end

  def projects = described_class.new(io: io, env: { "GEMNESIS_HOME" => @tmp })

  def make_project(name, build: false, age_seconds: 0)
    dir = File.join(@tmp, name)
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, "gemnesis.rb"), "# placeholder")
    return unless build

    rom = File.join(dir, "out", "rom.bin")
    FileUtils.mkdir_p(File.dirname(rom))
    File.write(rom, "x" * 131_072)
    File.utime(Time.now - age_seconds, Time.now - age_seconds, rom)
  end

  describe "#run" do
    it "reports when no projects exist" do
      expect(projects.run).to eq(0)
      expect(io.string).to include("Projects home", "no projects yet", "gemnesis new")
    end

    it "reports when the home directory itself is missing" do
      missing = File.join(@tmp, "never-created")
      instance = described_class.new(io: io, env: { "GEMNESIS_HOME" => missing })
      expect(instance.run).to eq(0)
      expect(io.string).to include("does not exist yet")
    end

    it "ignores directories without gemnesis.rb" do
      FileUtils.mkdir_p(File.join(@tmp, "random_dir"))
      expect(projects.run).to eq(0)
      expect(io.string).to include("no projects yet")
    end

    it "lists projects with build status + ROM size" do
      make_project("alpha", build: true, age_seconds: 90)
      make_project("beta",  build: false)

      expect(projects.run).to eq(0)
      output = io.string
      expect(output).to include("Projects in", "2 projects")
      expect(output).to include("alpha", "built 1m ago", "128 KB")
      expect(output).to include("beta",  "not built", "—")
    end

    it "uses singular project label when only one exists" do
      make_project("solo")
      projects.run
      expect(io.string).to include("(1 project)")
    end

    it "formats age across time scales" do
      [10, 70, 3700, 90_000].each do |secs|
        make_project("p#{secs}", build: true, age_seconds: secs)
      end

      projects.run
      ["10s ago", "1m ago", "1h ago", "1d ago"].each { |t| expect(io.string).to include(t) }
    end
  end
end
