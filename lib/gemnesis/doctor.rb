# frozen_string_literal: true

require "English"
require "rbconfig"

module Gemnesis
  # Environment verification: Docker, SGDK image, BlastEm, Ruby version.
  # Prints a ✓/✗ table. Exits non-zero on hard failures (Docker missing/daemon down,
  # Ruby too old). Soft failures (BlastEm missing, image not pulled) print warnings.
  class Doctor
    REQUIRED_RUBY = Gem::Version.new("3.4.0")
    DEFAULT_SGDK_IMAGE = "ghcr.io/stephane-d/sgdk:latest"

    Check = Struct.new(:label, :status, :detail, :hard) do
      def icon = { ok: "✓", warn: "⚠", fail: "✗" }.fetch(status)
    end

    def initialize(io: $stdout, env: ENV)
      @io = io
      @env = env
      @checks = []
    end

    def run
      check_ruby
      check_docker_binary
      check_docker_daemon
      check_sgdk_image
      check_blastem
      render
      exit_code
    end

    private

    def check_ruby
      current = Gem::Version.new(RUBY_VERSION)
      if current >= REQUIRED_RUBY
        ok("Ruby", "#{RUBY_VERSION} (>= #{REQUIRED_RUBY})")
      else
        fail_hard("Ruby", "#{RUBY_VERSION} (need >= #{REQUIRED_RUBY})")
      end
    end

    def check_docker_binary
      if which("docker")
        ok("docker on PATH", which("docker"))
      else
        fail_hard("docker on PATH", "install: https://orbstack.dev")
      end
    end

    def check_docker_daemon
      return skip("Docker daemon") unless which("docker")

      _, status = run_cmd("docker info --format '{{.ServerVersion}}'")
      if status.success?
        @docker_up = true
        ok("Docker daemon", "reachable")
      else
        @docker_up = false
        fail_hard("Docker daemon", "not reachable — is Docker running?")
      end
    end

    def check_sgdk_image
      return skip("SGDK image") unless which("docker") && @docker_up

      image = @env.fetch("GEMNESIS_SGDK_IMAGE", DEFAULT_SGDK_IMAGE)
      _, status = run_cmd("docker image inspect #{image}")
      if status.success?
        ok("SGDK image", image)
      else
        warn("SGDK image", "#{image} not pulled — auto-pull on first `gemnesis build`")
      end
    end

    def check_blastem
      blastem = which("blastem")
      retroarch_app = "/Applications/RetroArch.app/Contents/MacOS/RetroArch"

      if blastem
        ok("Emulator", "blastem at #{blastem} (open out/rom.bin to play)")
      elsif File.executable?(retroarch_app)
        ok("Emulator", "RetroArch detected (open out/rom.bin to play)")
      else
        warn("Emulator", "none detected — install via `brew install --cask retroarch` " \
                         "to play your ROM (any Mega Drive emulator works)")
      end
    end

    def render
      width = @checks.map { |c| c.label.length }.max
      @checks.each do |c|
        @io.puts format("  %s  %-#{width}s  %s", c.icon, c.label, c.detail)
      end
    end

    def exit_code
      @checks.any? { |c| c.status == :fail } ? 1 : 0
    end

    def ok(label, detail) = @checks << Check.new(label, :ok, detail, false)
    def warn(label, detail) = @checks << Check.new(label, :warn, detail, false)
    def fail_hard(label, detail) = @checks << Check.new(label, :fail, detail, true)
    def skip(label) = @checks << Check.new(label, :warn, "skipped (depends on prior check)", false)

    def which(cmd)
      exts = @env["PATHEXT"]&.split(";") || [""]
      @env.fetch("PATH", "").split(File::PATH_SEPARATOR).each do |dir|
        exts.each do |ext|
          path = File.join(dir, "#{cmd}#{ext}")
          return path if File.executable?(path) && !File.directory?(path)
        end
      end
      nil
    end

    def run_cmd(cmd)
      out = `#{cmd} 2>&1`
      [out, $CHILD_STATUS]
    end
  end
end
