# frozen_string_literal: true

RSpec.describe Gemnesis do
  it "has a version number" do
    expect(Gemnesis::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end
end
