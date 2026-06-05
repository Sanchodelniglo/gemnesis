# frozen_string_literal: true

require "fileutils"
require "open3"
require "rbconfig"

require_relative "config"
require_relative "rom_header"

module Gemnesis
  # Compiles a gemnesis project ROM by invoking the SGDK Docker image.
  #
  # Flow: parse gemnesis.rb → write src/config.h → ensure image → `docker run … make`.
  # All shell-outs use Open3 array form — no shell interpolation, no injection
  # via project paths or env-supplied image tags.
  class Builder
    DEFAULT_IMAGE = "ghcr.io/stephane-d/sgdk:latest"
    ROM_PATH = "out/rom.bin"
    SUMMARY_TAIL_LINES = 20

    def initialize(project_dir: Dir.pwd, io: $stdout, verbose: false, env: ENV)
      @project_dir = File.expand_path(project_dir)
      @io = io
      @verbose = verbose
      @env = env
    end

    def run
      ensure_project_root!
      cfg = Config.load_file(File.join(@project_dir, "gemnesis.rb"))
      write_config_header(cfg)
      write_rom_header(cfg)
      ensure_image
      warn_on_rosetta_fallback
      docker_build
      report_rom
      0
    end

    private

    def ensure_project_root!
      return if File.exist?(File.join(@project_dir, "gemnesis.rb"))

      raise Gemnesis::Error, "no gemnesis.rb found — run `gemnesis new NAME` first"
    end

    def write_config_header(cfg)
      target = File.join(@project_dir, "src", "config.h")
      FileUtils.mkdir_p(File.dirname(target))
      File.write(target, cfg.to_header)
    end

    def write_rom_header(cfg)
      target = File.join(@project_dir, "src", "boot", "rom_head.c")
      FileUtils.mkdir_p(File.dirname(target))
      File.write(target, RomHeader.new(cfg).to_c)
    end

    def image
      @env.fetch("GEMNESIS_SGDK_IMAGE", DEFAULT_IMAGE)
    end

    def ensure_image
      _, status = capture("docker", "image", "inspect", image)
      return if status.success?

      @io.puts "Pulling #{image} (first build only)…"
      success = stream("docker", "pull", image)
      raise Gemnesis::Error, "docker pull #{image} failed" unless success
    end

    def warn_on_rosetta_fallback
      return unless arm64_host?
      return if @arch_warned

      manifest, status = capture("docker", "manifest", "inspect", image)
      return unless status.success?
      return if manifest.include?("arm64")

      @io.puts "⚠ #{image} has no arm64 manifest — Docker will emulate via Rosetta (slower)."
      @arch_warned = true
    end

    def docker_build
      # `--platform linux/amd64` keeps the build deterministic on Apple Silicon:
      # the SGDK image is x86-only and Docker will use Rosetta to emulate.
      # The image's ENTRYPOINT runs `make -f $SGDK_PATH/makefile.gen $@` so we
      # don't pass `make` — empty $@ means "build default target".
      cmd = ["docker", "run", "--rm",
             "--platform", "linux/amd64",
             "-v", "#{@project_dir}:/src",
             image]

      if @verbose
        success = stream(*cmd)
      else
        out, status = capture(*cmd)
        success = status.success?
        @io.puts out.lines.last(SUMMARY_TAIL_LINES).join unless success
      end

      raise Gemnesis::Error, "build failed (docker exit ≠ 0)" unless success
    end

    def report_rom
      rom = File.join(@project_dir, ROM_PATH)
      raise Gemnesis::Error, "build succeeded but #{ROM_PATH} missing" unless File.exist?(rom)

      @io.puts "✓ #{ROM_PATH} (#{File.size(rom)} bytes)"
    end

    def arm64_host?
      RbConfig::CONFIG["host_cpu"] == "arm64"
    end

    def capture(*cmd)
      Open3.capture2e(*cmd)
    end

    def stream(*cmd)
      system(*cmd)
    end
  end
end
