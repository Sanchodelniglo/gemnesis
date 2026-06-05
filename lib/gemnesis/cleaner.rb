# frozen_string_literal: true

require "fileutils"

module Gemnesis
  # Removes build artifacts: out/, SGDK intermediates, generated config.h, and
  # rescomp-generated resource files. Safe to re-run.
  class Cleaner
    REMOVABLE_DIRS  = ["out", "src/boot"].freeze
    REMOVABLE_FILES = ["src/config.h", "src/boot/rom_head.c", "res/resources.h", "res/resources.s"].freeze
    REMOVABLE_GLOBS = ["src/**/*.o", "**/*.elf", "**/*.lst", "**/*.map"].freeze

    def initialize(project_dir: Dir.pwd, io: $stdout)
      @project_dir = File.expand_path(project_dir)
      @io = io
    end

    def run
      ensure_project_root!

      removed = remove_dirs + remove_files + remove_globs
      if removed.empty?
        @io.puts "Already clean."
      else
        removed.each { |path| @io.puts "  removed #{path}" }
      end
      0
    end

    private

    def ensure_project_root!
      return if File.exist?(File.join(@project_dir, "gemnesis.rb"))

      raise Gemnesis::Error, "no gemnesis.rb found — `gemnesis clean` must run in a project root"
    end

    def remove_dirs
      REMOVABLE_DIRS.filter_map do |rel|
        path = File.join(@project_dir, rel)
        next unless File.directory?(path)

        FileUtils.rm_rf(path)
        rel
      end
    end

    def remove_files
      REMOVABLE_FILES.filter_map do |rel|
        path = File.join(@project_dir, rel)
        next unless File.exist?(path)

        File.delete(path)
        rel
      end
    end

    def remove_globs
      REMOVABLE_GLOBS.flat_map do |pattern|
        Dir.glob(File.join(@project_dir, pattern)).map do |path|
          File.delete(path)
          path.sub("#{@project_dir}/", "")
        end
      end
    end
  end
end
