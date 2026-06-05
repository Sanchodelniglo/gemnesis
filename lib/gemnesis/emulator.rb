# frozen_string_literal: true

require "open3"

require_relative "builder"

module Gemnesis
  # Builds the ROM (if not already current) then launches it in an emulator.
  #
  # Search order: $GEMNESIS_EMULATOR override → BlastEm on PATH → RetroArch
  # with the Genesis Plus GX core. If none found, the ROM still ends up in
  # `out/rom.bin` and the install hint points the user at a working option.
  class Emulator
    ROM_PATH = "out/rom.bin"
    RETROARCH_APP = "/Applications/RetroArch.app/Contents/MacOS/RetroArch"
    GENESIS_CORE = "~/Library/Application Support/RetroArch/cores/genesis_plus_gx_libretro.dylib"

    def initialize(project_dir: Dir.pwd, io: $stdout, verbose: false, env: ENV)
      @project_dir = File.expand_path(project_dir)
      @io = io
      @verbose = verbose
      @env = env
    end

    def run
      Builder.new(project_dir: @project_dir, io: @io, verbose: @verbose, env: @env).run

      rom = File.join(@project_dir, ROM_PATH)
      launcher = pick_launcher
      return install_hint if launcher.nil?

      @io.puts "Launching #{launcher.first}…"
      success = system(*launcher, rom)
      raise Gemnesis::Error, "emulator exited non-zero" unless success

      0
    end

    private

    def pick_launcher
      override = @env["GEMNESIS_EMULATOR"]
      return [override] if override && !override.empty?

      blastem = which("blastem")
      return [blastem] if blastem

      core = File.expand_path(@env.fetch("GEMNESIS_RETROARCH_CORE", GENESIS_CORE))
      return [RETROARCH_APP, "-L", core] if File.executable?(RETROARCH_APP) && File.exist?(core)

      nil
    end

    def install_hint
      @io.puts "⚠ No emulator found. ROM is ready at #{ROM_PATH}."
      @io.puts "  Options:"
      @io.puts "    - Install RetroArch + Genesis Plus GX core (recommended on Apple Silicon):"
      @io.puts "        brew install --cask retroarch"
      @io.puts "    - Or override via GEMNESIS_EMULATOR=<command> gemnesis run"
      0
    end

    def which(cmd)
      @env.fetch("PATH", "").split(File::PATH_SEPARATOR).each do |dir|
        path = File.join(dir, cmd)
        return path if File.executable?(path) && !File.directory?(path)
      end
      nil
    end
  end
end
