# frozen_string_literal: true

require "gemnesis/config"
require "gemnesis/rom_header"
require "gemnesis/builder"
require "stringio"
require "tmpdir"

RSpec.describe "Builder + RomHeader integration" do
  let(:io) { StringIO.new }

  around do |example|
    Dir.mktmpdir("gemnesis-romhead-") do |dir|
      @tmp = dir
      File.write(File.join(dir, "gemnesis.rb"), <<~RUBY)
        Gemnesis.configure do |g|
          g.title  = "Hero"
          g.region = :ntsc
          g.author = "Me"
        end
      RUBY
      example.run
    end
  end

  def silent_builder
    ok = instance_double(Process::Status, success?: true)
    nope = instance_double(Process::Status, success?: false)
    b = Gemnesis::Builder.new(project_dir: @tmp, io: io, env: { "PATH" => "/usr/bin" })
    allow(b).to receive(:capture) do |*args|
      case args[0..2]
      when %w[docker image inspect]    then ["", ok]
      when %w[docker manifest inspect] then ["", nope]
      else
        FileUtils.mkdir_p(File.join(@tmp, "out"))
        File.write(File.join(@tmp, "out", "rom.bin"), "x")
        ["", ok]
      end
    end
    b
  end

  it "writes rom_head.c with the auto-marker on a fresh build" do
    silent_builder.run
    content = File.read(File.join(@tmp, "src", "boot", "rom_head.c"))
    expect(content).to include(Gemnesis::RomHeader::AUTO_MARKER)
    expect(content).to include('"Hero')
  end

  it "leaves a user-owned rom_head.c (no marker) alone on subsequent builds" do
    silent_builder.run

    user_path = File.join(@tmp, "src", "boot", "rom_head.c")
    user_content = "/* I edited this — no marker */\nconst int x = 1;\n"
    File.write(user_path, user_content)

    silent_builder.run
    expect(File.read(user_path)).to eq(user_content)
  end
end
