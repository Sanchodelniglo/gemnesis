# frozen_string_literal: true

require "open3"

require_relative "builder"

module Gemnesis
  # Builds the ROM (if not already current) then launches BlastEm on it.
  # If BlastEm isn't on PATH, builds anyway and prints the install hint —
  # the ROM is still usable in any other Mega Drive emulator.
  class Emulator
    EMULATOR_BIN = "blastem"
    ROM_PATH = "out/rom.bin"

    def initialize(project_dir: Dir.pwd, io: $stdout, verbose: false, env: ENV)
      @project_dir = File.expand_path(project_dir)
      @io = io
      @verbose = verbose
      @env = env
    end

    def run
      Builder.new(project_dir: @project_dir, io: @io, verbose: @verbose, env: @env).run

      rom = File.join(@project_dir, ROM_PATH)
      unless blastem_on_path?
        @io.puts "⚠ #{EMULATOR_BIN} not found on PATH. Install with: brew install blastem"
        @io.puts "  ROM is ready at #{ROM_PATH} — open it in any Mega Drive emulator."
        return 0
      end

      launch(rom)
      0
    end

    private

    def blastem_on_path?
      !which(EMULATOR_BIN).nil?
    end

    def which(cmd)
      @env.fetch("PATH", "").split(File::PATH_SEPARATOR).each do |dir|
        path = File.join(dir, cmd)
        return path if File.executable?(path) && !File.directory?(path)
      end
      nil
    end

    def launch(rom)
      @io.puts "Launching #{EMULATOR_BIN} #{ROM_PATH}…"
      success = system(EMULATOR_BIN, rom)
      raise Gemnesis::Error, "#{EMULATOR_BIN} exited non-zero" unless success
    end
  end
end
