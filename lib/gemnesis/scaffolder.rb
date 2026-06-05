# frozen_string_literal: true

require "fileutils"

module Gemnesis
  # Copies the bundled `hello_world` template into a new project directory.
  # Substitutes `{{NAME}}` placeholders in text files; leaves binaries alone.
  class Scaffolder
    TEMPLATE_DIR = File.expand_path("templates/hello_world", __dir__)
    NAME_RE = /\A[a-z0-9][a-z0-9_-]{0,62}\z/i
    BINARY_EXT = %w[.png .bin .gif .jpg].freeze

    def initialize(name, base_dir: Dir.pwd, io: $stdout)
      @name = name
      @base_dir = base_dir
      @io = io
    end

    def run
      validate_name!
      target = File.join(@base_dir, @name)
      raise Gemnesis::Error, "directory exists: #{target}" if File.exist?(target)

      FileUtils.mkdir_p(target)
      copy_template(TEMPLATE_DIR, target)
      substitute_placeholders(target)
      announce(target)
      0
    end

    private

    def validate_name!
      return if @name.match?(NAME_RE)

      raise Gemnesis::Error,
            "invalid project name #{@name.inspect} — use letters, digits, _ or - (no spaces)"
    end

    def copy_template(src, dst)
      Dir.glob(File.join(src, "**", "*"), File::FNM_DOTMATCH).each do |path|
        basename = File.basename(path)
        next if [".", ".."].include?(basename)
        next if File.directory?(path)

        rel = path.sub("#{src}/", "")
        out = File.join(dst, rel)
        FileUtils.mkdir_p(File.dirname(out))
        FileUtils.cp(path, out)
      end
    end

    def substitute_placeholders(target)
      Dir.glob(File.join(target, "**", "*"), File::FNM_DOTMATCH).each do |path|
        next if File.directory?(path)
        next if BINARY_EXT.include?(File.extname(path).downcase)

        content = File.read(path)
        next unless content.include?("{{NAME}}")

        File.write(path, content.gsub("{{NAME}}", @name))
      end
    end

    def announce(target)
      @io.puts "Created #{@name}/"
      @io.puts "  cd #{File.basename(target)}"
      @io.puts "  gemnesis run"
    end
  end
end
