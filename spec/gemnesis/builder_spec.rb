# frozen_string_literal: true

require "gemnesis/builder"
require "stringio"
require "tmpdir"

RSpec.describe Gemnesis::Builder do
  let(:io) { StringIO.new }
  let(:ok)   { instance_double(Process::Status, success?: true) }
  let(:nope) { instance_double(Process::Status, success?: false) }

  around do |example|
    Dir.mktmpdir("gemnesis-build-") do |dir|
      @tmp = dir
      File.write(File.join(dir, "gemnesis.rb"), <<~RUBY)
        Gemnesis.configure do |g|
          g.title  = "Test"
          g.region = :ntsc
          g.author = "Me"
        end
      RUBY
      example.run
    end
  end

  def builder(env: {}, verbose: false)
    described_class.new(project_dir: @tmp, io: io, verbose: verbose, env: { "PATH" => "/usr/bin" }.merge(env))
  end

  describe "#run" do
    it "writes src/config.h, runs docker, reports ROM" do
      File.write(File.join(@tmp, "make_succeeds"), "") # marker, not used

      instance = builder
      allow(instance).to receive(:capture).with("docker", "image", "inspect", anything).and_return(["", ok])
      allow(instance).to receive(:capture).with("docker", "manifest", "inspect", anything).and_return(["", nope])
      allow(instance).to receive(:capture).with("docker", "run", *any_args).and_wrap_original do |_, *_args|
        FileUtils.mkdir_p(File.join(@tmp, "out"))
        File.write(File.join(@tmp, "out", "rom.bin"), "X" * 1024)
        ["build ok", ok]
      end

      expect(instance.run).to eq(0)
      expect(File).to exist(File.join(@tmp, "src", "config.h"))
      expect(File.read(File.join(@tmp, "src", "config.h"))).to include('GAME_TITLE  "Test"')
      expect(io.string).to include("out/rom.bin", "1024 bytes")
    end

    it "aborts when no gemnesis.rb is present" do
      File.delete(File.join(@tmp, "gemnesis.rb"))
      expect { builder.run }.to raise_error(Gemnesis::Error, /no gemnesis.rb/)
    end

    it "pulls the image when missing, then builds" do
      instance = builder
      allow(instance).to receive(:capture).with("docker", "image", "inspect", anything).and_return(
        ["No such image", nope], ["", ok]
      )
      allow(instance).to receive(:capture).with("docker", "manifest", "inspect", anything).and_return(["", nope])
      allow(instance).to receive(:stream).with("docker", "pull", anything).and_return(true)
      allow(instance).to receive(:capture).with("docker", "run", *any_args) do
        FileUtils.mkdir_p(File.join(@tmp, "out"))
        File.write(File.join(@tmp, "out", "rom.bin"), "x")
        ["", ok]
      end

      expect(instance.run).to eq(0)
      expect(io.string).to include("Pulling", "out/rom.bin")
    end

    it "surfaces docker pull failures" do
      instance = builder
      allow(instance).to receive(:capture).with("docker", "image", "inspect", anything).and_return(["", nope])
      allow(instance).to receive(:stream).with("docker", "pull", anything).and_return(false)

      expect { instance.run }.to raise_error(Gemnesis::Error, /docker pull.*failed/)
    end

    it "honors GEMNESIS_SGDK_IMAGE override" do
      instance = builder(env: { "GEMNESIS_SGDK_IMAGE" => "custom/sgdk:v1" })
      allow(instance).to receive(:capture).with("docker", "image", "inspect", "custom/sgdk:v1").and_return(["", ok])
      allow(instance).to receive(:capture).with("docker", "manifest", "inspect",
                                                "custom/sgdk:v1").and_return(["", nope])
      allow(instance).to receive(:capture).with("docker", "run", "--rm", "--platform", "linux/amd64",
                                                "--user", anything, "-v", anything, "custom/sgdk:v1") do
        FileUtils.mkdir_p(File.join(@tmp, "out"))
        File.write(File.join(@tmp, "out", "rom.bin"), "x")
        ["", ok]
      end

      instance.run
      expect(File).to exist(File.join(@tmp, "out", "rom.bin"))
    end

    it "shows last 20 lines of output on build failure (summary mode)" do
      instance = builder
      allow(instance).to receive(:capture).with("docker", "image", "inspect", anything).and_return(["", ok])
      allow(instance).to receive(:capture).with("docker", "manifest", "inspect", anything).and_return(["", nope])
      err = (1..50).map { |i| "line #{i}" }.join("\n")
      allow(instance).to receive(:capture).with("docker", "run", *any_args).and_return([err, nope])

      expect { instance.run }.to raise_error(Gemnesis::Error, /build failed/)
      expect(io.string).to include("line 50")
      expect(io.string).not_to include("line 1\n")
    end
  end
end
