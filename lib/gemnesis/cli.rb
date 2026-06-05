# frozen_string_literal: true

require "thor"

module Gemnesis
  # Thor-based command-line interface for gemnesis.
  # The 6-command surface is frozen for 0.1.0 — see PLAN-MVP.
  class CLI < Thor
    class_option :verbose, type: :boolean, aliases: "-v", desc: "Stream full output"

    def self.exit_on_failure? = true

    desc "version", "Print gemnesis version"
    def version
      puts Gemnesis::VERSION
    end

    desc "new NAME", "Scaffold a new gemnesis project"
    def new(name)
      require "gemnesis/scaffolder"
      exit Gemnesis::Scaffolder.new(name).run
    rescue Gemnesis::Error => e
      warn "Error: #{e.message}"
      exit 1
    end

    desc "doctor", "Check environment (Docker, SGDK image, BlastEm, Ruby)"
    def doctor
      require "gemnesis/doctor"
      exit Gemnesis::Doctor.new.run
    end

    desc "build", "Build ROM via SGDK Docker image"
    def build
      require "gemnesis/builder"
      exit Gemnesis::Builder.new(verbose: options[:verbose]).run
    rescue Gemnesis::Error => e
      warn "Error: #{e.message}"
      exit 1
    end

    # `run` is a Thor reserved word — register the command name, define under an alias
    desc "run", "Build ROM and launch BlastEm"
    map "run" => :launch
    def launch
      raise NotImplementedError, "emulator launcher lands in PLAN-MVP Phase 7"
    end

    desc "clean", "Remove build artifacts (out/)"
    def clean
      raise NotImplementedError, "clean lands in PLAN-MVP Phase 8"
    end
  end
end
