# frozen_string_literal: true

require "gemnesis/config"
require "tmpdir"

RSpec.describe Gemnesis::Config do
  around do |example|
    Dir.mktmpdir("gemnesis-cfg-") do |dir|
      @tmp = dir
      example.run
    end
  end

  def write_config(body)
    path = File.join(@tmp, "gemnesis.rb")
    File.write(path, body)
    path
  end

  describe ".load_file" do
    it "parses a valid gemnesis.rb" do
      path = write_config(<<~RUBY)
        Gemnesis.configure do |g|
          g.title  = "My Game"
          g.region = :ntsc
          g.author = "Alice"
        end
      RUBY

      cfg = described_class.load_file(path)
      expect(cfg.title).to eq("My Game")
      expect(cfg.region).to eq(:ntsc)
      expect(cfg.author).to eq("Alice")
    end

    it "raises when file is missing" do
      expect { described_class.load_file("/nope/gemnesis.rb") }
        .to raise_error(Gemnesis::Error, /no gemnesis.rb/)
    end

    it "raises when the file has no Gemnesis.configure block" do
      path = write_config("# empty")
      expect { described_class.load_file(path) }
        .to raise_error(Gemnesis::Error, /missing.*configure.*block/)
    end

    it "wraps Ruby parse errors with a friendly prefix" do
      path = write_config("Gemnesis.configure do |g|\n  g.title = ")
      expect { described_class.load_file(path) }
        .to raise_error(Gemnesis::Error, /gemnesis.rb:/)
    end

    it "rejects too-long titles" do
      path = write_config(<<~RUBY)
        Gemnesis.configure do |g|
          g.title  = "x" * 49
          g.region = :ntsc
          g.author = "A"
        end
      RUBY
      expect { described_class.load_file(path) }
        .to raise_error(Gemnesis::Error, /title too long/)
    end

    it "rejects non-ASCII titles" do
      path = write_config(<<~RUBY)
        Gemnesis.configure do |g|
          g.title  = "Pokémon"
          g.region = :ntsc
          g.author = "A"
        end
      RUBY
      expect { described_class.load_file(path) }
        .to raise_error(Gemnesis::Error, /ASCII/)
    end

    it "rejects unknown regions" do
      path = write_config(<<~RUBY)
        Gemnesis.configure do |g|
          g.title  = "ok"
          g.region = :japan
          g.author = "A"
        end
      RUBY
      expect { described_class.load_file(path) }
        .to raise_error(Gemnesis::Error, /region invalid/)
    end

    it "rejects blank author" do
      path = write_config(<<~RUBY)
        Gemnesis.configure do |g|
          g.title  = "ok"
          g.region = :pal
          g.author = ""
        end
      RUBY
      expect { described_class.load_file(path) }
        .to raise_error(Gemnesis::Error, /author required/)
    end
  end

  describe "#to_header" do
    it "renders a C header with escaped strings" do
      cfg = described_class.new
      cfg.title = 'My "Cool" Game'
      cfg.region = :both
      cfg.author = "Alice"

      header = cfg.to_header
      expect(header).to include('#define GAME_TITLE  "My \\"Cool\\" Game"')
      expect(header).to include('#define GAME_REGION "NTSC/PAL"')
      expect(header).to include('#define GAME_AUTHOR "Alice"')
    end
  end
end
