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

  describe "#run" do
    it "warns and exits 0 when blastem is missing" do
      instance = emulator
      stub_successful_build

      expect(instance.run).to eq(0)
      expect(io.string).to include("⚠", "blastem not found", "brew install blastem")
    end

    it "launches blastem when on PATH" do
      blastem_dir = File.join(@tmp, "bin")
      FileUtils.mkdir_p(blastem_dir)
      blastem = File.join(blastem_dir, "blastem")
      File.write(blastem, "#!/bin/sh\nexit 0\n")
      File.chmod(0o755, blastem)

      instance = emulator(env: { "PATH" => blastem_dir })
      stub_successful_build
      allow(instance).to receive(:system).with("blastem", anything).and_return(true)

      expect(instance.run).to eq(0)
      expect(io.string).to include("Launching blastem")
    end

    it "raises when blastem exits non-zero" do
      blastem_dir = File.join(@tmp, "bin")
      FileUtils.mkdir_p(blastem_dir)
      blastem = File.join(blastem_dir, "blastem")
      File.write(blastem, "")
      File.chmod(0o755, blastem)

      instance = emulator(env: { "PATH" => blastem_dir })
      stub_successful_build
      allow(instance).to receive(:system).with("blastem", anything).and_return(false)

      expect { instance.run }.to raise_error(Gemnesis::Error, /blastem.*non-zero/)
    end
  end
end
