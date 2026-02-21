# frozen_string_literal: true

require "spec_helper"
require "ticktick/auth/oauth_flow"

RSpec.describe Ticktick::Auth::OauthFlow do
  let(:client_id) { "test_client_id" }
  let(:client_secret) { "test_client_secret" }
  let(:port) { 18_081 }
  let(:flow) { described_class.new(client_id: client_id, client_secret: client_secret, port: port) }
  let(:callback_server) { instance_double(Ticktick::Auth::CallbackServer) }
  let(:redirect_uri) { "http://localhost:#{port}/callback" }

  before do
    allow(Ticktick::Auth::CallbackServer).to receive(:new).with(port: port).and_return(callback_server)
    allow(flow).to receive(:puts)
  end

  describe "#run" do
    let(:state) { "fixed_state_value" }
    let(:code) { "auth_code_123" }

    before do
      allow(SecureRandom).to receive(:hex).with(16).and_return(state)
    end

    context "正常フロー" do
      it "access_token を返す" do
        allow(callback_server).to receive(:wait_for_code).with(timeout: 300)
                                                         .and_return({ code: code, state: state })

        stub_request(:post, "https://ticktick.com/oauth/token")
          .to_return(
            status: 200,
            body: { access_token: "my_access_token" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        result = flow.run
        expect(result).to eq("my_access_token")
      end

      it "正しい Basic 認証ヘッダーでトークンを要求する" do
        allow(callback_server).to receive(:wait_for_code).with(timeout: 300)
                                                         .and_return({ code: code, state: state })

        expected_credentials = Base64.strict_encode64("#{client_id}:#{client_secret}")
        stub = stub_request(:post, "https://ticktick.com/oauth/token")
               .with(headers: { "Authorization" => "Basic #{expected_credentials}" })
               .to_return(
                 status: 200,
                 body: { access_token: "my_access_token" }.to_json,
                 headers: { "Content-Type" => "application/json" }
               )

        flow.run
        expect(stub).to have_been_requested
      end
    end

    context "タイムアウト" do
      it "TimeoutError を raise する" do
        allow(callback_server).to receive(:wait_for_code).with(timeout: 300).and_return(nil)

        expect { flow.run }.to raise_error(described_class::TimeoutError)
      end
    end

    context "認可拒否" do
      it "DeniedError を raise する" do
        allow(callback_server).to receive(:wait_for_code).with(timeout: 300)
                                                         .and_return({ error: "access_denied" })

        expect { flow.run }.to raise_error(described_class::DeniedError, /access_denied/)
      end
    end

    context "state 不一致" do
      it "Error を raise する" do
        allow(callback_server).to receive(:wait_for_code).with(timeout: 300)
                                                         .and_return({ code: code, state: "wrong_state" })

        expect { flow.run }.to raise_error(described_class::Error, /State mismatch/)
      end
    end

    context "HTTP エラー" do
      it "Error を raise する" do
        allow(callback_server).to receive(:wait_for_code).with(timeout: 300)
                                                         .and_return({ code: code, state: state })

        stub_request(:post, "https://ticktick.com/oauth/token")
          .to_return(status: 400, body: "Bad Request")

        expect { flow.run }.to raise_error(described_class::Error, /Token exchange failed/)
      end
    end

    context "ネットワーク障害" do
      it "NetworkError を raise する" do
        allow(callback_server).to receive(:wait_for_code).with(timeout: 300)
                                                         .and_return({ code: code, state: state })

        stub_request(:post, "https://ticktick.com/oauth/token")
          .to_raise(Faraday::ConnectionFailed.new("connection refused"))

        expect { flow.run }.to raise_error(described_class::NetworkError, /Network error/)
      end
    end

    context "access_token が欠如" do
      it "Error を raise する" do
        allow(callback_server).to receive(:wait_for_code).with(timeout: 300)
                                                         .and_return({ code: code, state: state })

        stub_request(:post, "https://ticktick.com/oauth/token")
          .to_return(
            status: 200,
            body: { token_type: "Bearer" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )

        expect { flow.run }.to raise_error(described_class::Error, /No access_token/)
      end
    end
  end
end
