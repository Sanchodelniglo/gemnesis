# frozen_string_literal: true

require "gemnesis/doctor"
require "stringio"

RSpec.describe Gemnesis::Doctor do
  let(:io) { StringIO.new }
  let(:env) { { "PATH" => "/usr/bin" } }

  def doctor(env_overrides = {}) = described_class.new(io: io, env: env.merge(env_overrides))

  describe "#run" do
    context "when docker is missing" do
      it "fails hard with install hint" do
        instance = doctor
        allow(instance).to receive(:which).and_call_original
        allow(instance).to receive(:which).with("docker").and_return(nil)
        allow(instance).to receive(:which).with("blastem").and_return(nil)

        expect(instance.run).to eq(1)
        expect(io.string).to include("✗", "docker on PATH", "orbstack")
      end
    end

    context "when ruby version is too old" do
      it "fails hard" do
        stub_const("RUBY_VERSION", "3.3.5")
        instance = doctor
        allow(instance).to receive(:which).and_return(nil)

        expect(instance.run).to eq(1)
        expect(io.string).to include("✗", "Ruby", "3.3.5")
      end
    end

    context "when blastem is missing but docker present" do
      it "warns (does not fail)" do
        instance = doctor
        allow(instance).to receive(:which).and_call_original
        allow(instance).to receive(:which).with("docker").and_return("/usr/bin/docker")
        allow(instance).to receive(:which).with("blastem").and_return(nil)
        allow(instance).to receive(:run_cmd).and_return(["1.0", instance_double(Process::Status, success?: true)])

        expect(instance.run).to eq(0)
        expect(io.string).to include("⚠", "BlastEm", "brew install blastem")
      end
    end

    context "when SGDK image is not pulled" do
      it "warns and notes auto-pull on build" do
        instance = doctor
        allow(instance).to receive(:which).and_call_original
        allow(instance).to receive(:which).with("docker").and_return("/usr/bin/docker")
        allow(instance).to receive(:which).with("blastem").and_return("/usr/bin/blastem")

        ok_status = instance_double(Process::Status, success?: true)
        fail_status = instance_double(Process::Status, success?: false)
        allow(instance).to receive(:run_cmd).with(/docker info/).and_return(["1.0", ok_status])
        allow(instance).to receive(:run_cmd).with(/docker image inspect/).and_return(["", fail_status])

        expect(instance.run).to eq(0)
        expect(io.string).to include("⚠", "SGDK image", "auto-pull")
      end
    end

    context "when GEMNESIS_SGDK_IMAGE overrides default" do
      it "checks the overridden image" do
        instance = doctor("GEMNESIS_SGDK_IMAGE" => "custom/sgdk:v1")
        allow(instance).to receive(:which).and_call_original
        allow(instance).to receive(:which).with("docker").and_return("/usr/bin/docker")
        allow(instance).to receive(:which).with("blastem").and_return("/usr/bin/blastem")

        ok_status = instance_double(Process::Status, success?: true)
        allow(instance).to receive(:run_cmd).with(/docker info/).and_return(["1.0", ok_status])
        allow(instance).to receive(:run_cmd).with(%r{docker image inspect custom/sgdk:v1}).and_return(["", ok_status])

        instance.run
        expect(io.string).to include("custom/sgdk:v1")
      end
    end
  end
end
