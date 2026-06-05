# frozen_string_literal: true

require "gemnesis/scaffolder"
require "stringio"
require "tmpdir"

RSpec.describe Gemnesis::Scaffolder do
  let(:io) { StringIO.new }

  around do |example|
    Dir.mktmpdir("gemnesis-test-") do |dir|
      @tmp = dir
      example.run
    end
  end

  def scaffold(name) = described_class.new(name, base_dir: @tmp, io: io)

  describe "#run" do
    it "creates the project directory with all template files" do
      expect(scaffold("demo").run).to eq(0)

      project = File.join(@tmp, "demo")
      expect(File).to exist(File.join(project, "gemnesis.rb"))
      expect(File).to exist(File.join(project, "src/main.c"))
      expect(File).to exist(File.join(project, "res/resources.res"))
      expect(File).to exist(File.join(project, "res/hero.png"))
      expect(File).to exist(File.join(project, "res/lab_bg.png"))
      expect(File).to exist(File.join(project, "README.md"))
      expect(File).to exist(File.join(project, ".gitignore"))
    end

    it "substitutes {{NAME}} in text files" do
      scaffold("super-game").run

      project = File.join(@tmp, "super-game")
      expect(File.read("#{project}/README.md")).to start_with("# super-game")
      expect(File.read("#{project}/src/main.c")).to include("super-game")
    end

    it "fills gemnesis.rb from attrs (title, author, region)" do
      described_class.new("hero",
                          attrs: { title: "Hero Quest", author: "Alice", region: "pal" },
                          base_dir: @tmp, io: io).run

      gemnesis_rb = File.read(File.join(@tmp, "hero", "gemnesis.rb"))
      expect(gemnesis_rb).to include('g.title  = "Hero Quest"')
      expect(gemnesis_rb).to include("g.region = :pal")
      expect(gemnesis_rb).to include('g.author = "Alice"')
    end

    it "defaults title from a humanized project name, region :ntsc, author 'You'" do
      scaffold("my-cool-game").run
      gemnesis_rb = File.read(File.join(@tmp, "my-cool-game", "gemnesis.rb"))
      expect(gemnesis_rb).to include('g.title  = "My Cool Game"')
      expect(gemnesis_rb).to include("g.region = :ntsc")
      expect(gemnesis_rb).to include('g.author = "You"')
    end

    it "rejects an invalid region in attrs" do
      expect do
        described_class.new("x", attrs: { region: "japan" }, base_dir: @tmp, io: io).run
      end.to raise_error(Gemnesis::Error, /invalid region/)
    end

    it "leaves binary files (PNG) untouched" do
      template_png = File.binread("#{described_class::TEMPLATE_DIR}/res/hero.png")
      scaffold("demo").run
      copied_png = File.binread(File.join(@tmp, "demo/res/hero.png"))

      expect(copied_png).to eq(template_png)
    end

    it "rejects names with spaces or special chars" do
      expect { scaffold("bad name").run }.to raise_error(Gemnesis::Error, /invalid project name/)
      expect { scaffold("../escape").run }.to raise_error(Gemnesis::Error, /invalid project name/)
    end

    it "refuses to overwrite an existing directory" do
      FileUtils.mkdir(File.join(@tmp, "existing"))
      expect { scaffold("existing").run }.to raise_error(Gemnesis::Error, /directory exists/)
    end

    it "prints next steps on success" do
      scaffold("demo").run
      expect(io.string).to include("Created demo/", "gemnesis build")
    end
  end
end
