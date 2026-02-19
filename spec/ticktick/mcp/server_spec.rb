# frozen_string_literal: true

RSpec.describe Ticktick::Mcp::Server do
  it "has a version number" do
    expect(Ticktick::Mcp::Server::VERSION).not_to be nil
  end

  describe ".build" do
    it "returns an MCP::Server instance" do
      server = described_class.build
      expect(server).to be_a(MCP::Server)
    end
  end
end
