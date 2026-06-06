# frozen_string_literal: true

require "thor"

module Gemnesis
  # Thor-based command-line interface for gemnesis.
  # The 6-command surface is frozen for 0.1.0 — see PLAN-MVP.
  class CLI < Thor
    class_option :verbose, type: :boolean, aliases: "-v", desc: "Stream full output"

    def self.exit_on_failure? = true

    desc "version", "Print gemnesis version"
    map %w[--version -V] => :version
    def version
      puts Gemnesis::VERSION
    end

    desc "new NAME", "Scaffold a new gemnesis project (defaults to $GEMNESIS_HOME or ~/gemnesis)"
    method_option :yes,  type: :boolean, aliases: "-y", desc: "Skip prompts, use defaults"
    method_option :here, type: :boolean, aliases: "-H", desc: "Create in current directory instead of $GEMNESIS_HOME"
    def new(name)
      require "gemnesis/scaffolder"
      attrs = collect_new_attrs(name)
      base_dir = options[:here] ? Dir.pwd : ensure_home_dir
      exit Gemnesis::Scaffolder.new(name, attrs: attrs, base_dir: base_dir).run
    rescue Gemnesis::Error => e
      warn "Error: #{e.message}"
      exit 1
    end

    no_commands do
      def collect_new_attrs(name)
        defaults = default_attrs(name)
        return defaults if options[:yes] || !$stdin.tty?

        say "Configuring #{name} — press Enter to accept defaults.", :cyan
        {
          title: ask("  Title?  [#{defaults[:title]}]", default: defaults[:title]),
          author: ask("  Author? [#{defaults[:author]}]", default: defaults[:author]),
          region: ask("  Region? [#{defaults[:region]}]", default: defaults[:region],
                                                          limited_to: Gemnesis::Scaffolder::VALID_REGIONS)
        }
      end

      def default_attrs(name)
        {
          title: Gemnesis::Scaffolder.humanize_name(name),
          author: git_user || "You",
          region: "ntsc"
        }
      end

      def git_user
        out = `git config user.name 2>/dev/null`.strip
        out.empty? ? nil : out
      end

      def ensure_home_dir
        home = File.expand_path(ENV.fetch("GEMNESIS_HOME", "~/gemnesis"))
        require "fileutils"
        FileUtils.mkdir_p(home)
        home
      end
    end

    desc "doctor", "Check environment (Docker, SGDK image, emulator, Ruby)"
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

    desc "projects", "List gemnesis projects in $GEMNESIS_HOME with build status"
    def projects
      require "gemnesis/projects"
      exit Gemnesis::Projects.new.run
    end

    desc "clean", "Remove build artifacts (out/, src/config.h, generated resources)"
    def clean
      require "gemnesis/cleaner"
      exit Gemnesis::Cleaner.new.run
    rescue Gemnesis::Error => e
      warn "Error: #{e.message}"
      exit 1
    end
  end
end
