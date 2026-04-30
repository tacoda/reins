require "spec_helper"
require "rack/session"

class FlashController < Reins::Controller
  def write_then_redirect
    flash[:notice] = "set!"
    redirect_to "/flash/read"
  end

  def read
    msg = flash[:notice]
    response(msg ? "notice: #{msg}" : "no notice")
  end

  def set_now_and_render
    flash.now[:alert] = "now!"
    response("now alert: #{flash[:alert]}")
  end
end

RSpec.describe "Flash" do
  include Rack::Test::Methods

  let(:app) do
    reins_app = Reins::Application.new
    reins_app.route do
      get "/flash/write", "flash#write_then_redirect"
      get "/flash/read",  "flash#read"
      get "/flash/now",   "flash#set_now_and_render"
    end
    Rack::Builder.new do
      use Rack::Session::Cookie, secret: "x" * 64
      run reins_app
    end.to_app
  end

  it "flash[:notice] persists to the next request and clears after" do
    get "/flash/write"
    follow_redirect!
    expect(last_response.body).to eq("notice: set!")

    get "/flash/read"
    expect(last_response.body).to eq("no notice")
  end

  it "flash.now[:alert] is readable on the current request only" do
    get "/flash/now"
    expect(last_response.body).to eq("now alert: now!")

    get "/flash/read"
    expect(last_response.body).to eq("no notice")
  end
end
