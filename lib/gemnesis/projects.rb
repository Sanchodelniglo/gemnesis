# frozen_string_literal: true

module Gemnesis
  # Lists all gemnesis projects in $GEMNESIS_HOME with build status + ROM size.
  # A directory counts as a "project" iff it contains a `gemnesis.rb`.
  class Projects
    HOME_DEFAULT = "~/gemnesis"

    def initialize(io: $stdout, env: ENV)
      @io = io
      @env = env
    end

    def run
      home = resolve_home
      return announce_empty(home, "directory does not exist yet") unless File.directory?(home)

      entries = projects_in(home)
      return announce_empty(home, "no projects yet — try `gemnesis new my_game`") if entries.empty?

      header(home, entries.size)
      entries.sort.each { |name| render_row(home, name) }
      footer
      0
    end

    private

    def resolve_home
      File.expand_path(@env.fetch("GEMNESIS_HOME", HOME_DEFAULT))
    end

    def projects_in(home)
      Dir.children(home).select do |c|
        File.directory?(File.join(home, c)) && File.exist?(File.join(home, c, "gemnesis.rb"))
      end
    end

    def header(home, count)
      suffix = count == 1 ? "project" : "projects"
      @io.puts "Projects in #{home} (#{count} #{suffix}):"
      @io.puts
    end

    def announce_empty(home, reason)
      @io.puts "Projects home: #{home}"
      @io.puts "  #{reason}"
      0
    end

    def footer
      @io.puts
      @io.puts "  (only projects in this home are listed — `--here` projects live elsewhere)"
    end

    def render_row(home, name)
      rom = File.join(home, name, "out", "rom.bin")
      built = File.exist?(rom)
      status = built ? "built #{ago(File.mtime(rom))}" : "not built"
      size = built ? format_size(File.size(rom)) : "—"
      @io.puts format("  %<name>-22s %<status>-22s %<size>s", name: name, status: status, size: size)
    end

    def ago(time)
      seconds = (Time.now - time).to_i
      case seconds
      when 0..59             then "#{seconds}s ago"
      when 60..3599          then "#{seconds / 60}m ago"
      when 3600..86_399      then "#{seconds / 3600}h ago"
      else                        "#{seconds / 86_400}d ago"
      end
    end

    def format_size(bytes)
      return "#{bytes} B" if bytes < 1024
      return "#{bytes / 1024} KB" if bytes < 1024 * 1024

      "#{(bytes / 1024.0 / 1024).round(1)} MB"
    end
  end
end
