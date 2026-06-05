# frozen_string_literal: true

require "gemnesis/emulator"
require "stringio"
require "tmpdir"

RSpec.describe Gemnesis::Emulator do
  let(:io) { StringIO.new }

  around do |example|
    Dir.mktmpdir("gemnesis-emu-") do |dir|
      @tmp = dir
      example.run
    end
  end

  def emulator(env: {})
    described_class.new(project_dir: @tmp, io: io, env: { "PATH" => "/usr/bin" }.merge(env))
  end

  def stub_successful_build
    builder = instance_double(Gemnesis::Builder, run: 0)
    allow(Gemnesis::Builder).to receive(:new).and_return(builder)
    FileUtils.mkdir_p(File.join(@tmp, "out"))
    File.write(File.join(@tmp, "out", "rom.bin"), "x")
  end

  # Default: isolate from real RetroArch on this machine. Tests that want
  # the fallback path opt back in by stubbing the const to a real file.
  before do
    stub_const("#{described_class}::RETROARCH_APP", "/nonexistent/RetroArch")
    stub_const("#{described_class}::GENESIS_CORE",  "/nonexistent/core.dylib")
  end

  def make_executable(dir, name)
    FileUtils.mkdir_p(dir)
    path = File.join(dir, name)
    File.write(path, "")
    File.chmod(0o755, path)
    path
  end

  describe "#run" do
    it "uses GEMNESIS_EMULATOR override when set" do
      instance = emulator(env: { "GEMNESIS_EMULATOR" => "/usr/local/bin/custom" })
      stub_successful_build
      allow(instance).to receive(:system).with("/usr/local/bin/custom", anything).and_return(true)

      expect(instance.run).to eq(0)
      expect(io.string).to include("Launching /usr/local/bin/custom")
    end

    it "prefers blastem when it is on PATH" do
      bin_dir = File.join(@tmp, "bin")
      blastem = make_executable(bin_dir, "blastem")

      instance = emulator(env: { "PATH" => bin_dir })
      stub_successful_build
      allow(instance).to receive(:system).with(blastem, anything).and_return(true)

      expect(instance.run).to eq(0)
      expect(io.string).to include("Launching", "blastem")
    end

    it "falls back to RetroArch + Genesis Plus GX core when blastem absent" do
      core = File.join(@tmp, "core.dylib")
      File.write(core, "")
      retroarch = make_executable(@tmp, "RetroArch")
      stub_const("#{described_class}::RETROARCH_APP", retroarch)

      instance = emulator(env: { "GEMNESIS_RETROARCH_CORE" => core })
      stub_successful_build
      allow(instance).to receive(:system).with(retroarch, "-L", core, anything).and_return(true)

      expect(instance.run).to eq(0)
      expect(io.string).to include("Launching #{retroarch}")
    end

    it "prints install hint when nothing is available" do
      instance = emulator
      stub_successful_build

      expect(instance.run).to eq(0)
      expect(io.string).to include("⚠", "No emulator found", "brew install --cask retroarch")
    end

    it "raises when emulator exits non-zero" do
      bin_dir = File.join(@tmp, "bin")
      make_executable(bin_dir, "blastem")

      instance = emulator(env: { "PATH" => bin_dir })
      stub_successful_build
      allow(instance).to receive(:system).and_return(false)

      expect { instance.run }.to raise_error(Gemnesis::Error, /emulator.*non-zero/)
    end
  end
end
