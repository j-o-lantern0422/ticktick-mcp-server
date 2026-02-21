# frozen_string_literal: true

require "spec_helper"
require "net/http"
require "ticktick/auth/callback_server"

RSpec.describe Ticktick::Auth::CallbackServer do
  # localhost への実通信を許可（WEBrick 統合テストのため）
  before(:all) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  after(:all) do
    WebMock.disable_net_connect!(allow_localhost: false)
  end

  let(:port) { 18_080 }
  let(:server) { described_class.new(port: port) }

  describe "#wait_for_code" do
    it "code と state を受け取って返す" do
      result = nil
      thread = Thread.new { result = server.wait_for_code(timeout: 5) }

      sleep 0.3
      Net::HTTP.get(URI("http://localhost:#{port}/callback?code=test_code&state=test_state"))
      thread.join(3)

      expect(result).to eq({ code: "test_code", state: "test_state" })
    end

    it "error パラメータを受け取って返す" do
      result = nil
      thread = Thread.new { result = server.wait_for_code(timeout: 5) }

      sleep 0.3
      Net::HTTP.get(URI("http://localhost:#{port}/callback?error=access_denied"))
      thread.join(3)

      expect(result).to eq({ error: "access_denied" })
    end

    it "タイムアウト時に nil を返す" do
      result = server.wait_for_code(timeout: 0.2)
      expect(result).to be_nil
    end
  end
end
