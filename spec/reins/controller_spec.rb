require "spec_helper"
require "json"
require "rack/session"

class RenderingController < Reins::Controller
  # No render call in show/missing_template — exercises auto-render.
  def show; end
  def show_locals = render(:show_locals, locals: { greeting: "hi" })
  def plain = render(plain: "x")
  def html = render(html: "<p>raw</p>")
  def json = render(json: { ok: true })
  def custom_status = render(:show, status: 201)
  def symbolic_status = render(:show, status: :created)
  def absolute_template = render(template: "shared/notice")

  def double_render
    render :show
    render :show
  end

  def missing_template; end
end

class RedirectingController < Reins::Controller
  def go = redirect_to("/login")
  def go_moved = redirect_to("/x", status: :moved_permanently)

  def double
    render plain: "x"
    redirect_to "/y"
  end
end

class HeadActionController < Reins::Controller
  def empty = head(:no_content)
  def with_headers = head(:unauthorized, retry_after: "60")
end

class RespondingController < Reins::Controller
  def show
    respond_to do |format|
      format.html { render plain: "html-body" }
      format.json { render json: { fmt: "json" } }
    end
  end

  def html_only
    respond_to do |format|
      format.html { render plain: "html-body" }
    end
  end
end

class SessionsController < Reins::Controller
  def write
    session[:foo] = "bar"
    response("ok")
  end

  def read = response("session.foo=#{session[:foo].inspect}")
end

class FilterParentController < Reins::Controller
  CALLS = [] # rubocop:disable Style/MutableConstant
  before_action :p_before
  after_action  :p_after

  def p_before = self.class::CALLS.<<(:p_before)
  def p_after = self.class::CALLS.<<(:p_after)
end

class FilterChildController < FilterParentController
  before_action :c_before
  before_action :scoped, only: [:scoped_action]
  before_action :unscoped, except: [:bare]
  around_action :wrap

  def index
    self.class::CALLS << :index
    response("ok")
  end

  def bare
    self.class::CALLS << :bare
    response("ok")
  end

  def scoped_action
    self.class::CALLS << :scoped_action
    response("ok")
  end

  def c_before = self.class::CALLS.<<(:c_before)
  def scoped = self.class::CALLS.<<(:scoped)
  def unscoped = self.class::CALLS.<<(:unscoped)

  def wrap
    self.class::CALLS << :wrap_in
    yield
    self.class::CALLS << :wrap_out
  end
end

class HaltingController < Reins::Controller
  CALLS = [] # rubocop:disable Style/MutableConstant
  before_action :gatekeeper
  after_action  :should_not_run

  def index
    self.class::CALLS << :action
    response("ok")
  end

  def gatekeeper
    self.class::CALLS << :gatekeeper
    redirect_to "/login"
  end

  def should_not_run
    self.class::CALLS << :after
  end
end

# Helpers shared across the controller specs.
module ControllerSpecAppBuilder
  def build_app(&)
    reins_app = Reins::Application.new
    reins_app.route(&)
    reins_app
  end

  def build_app_with_session(&)
    reins_app = build_app(&)
    Rack::Builder.new do
      use Rack::Session::Cookie, secret: "x" * 64
      run reins_app
    end.to_app
  end

  def make_views(tmp_root)
    FileUtils.mkdir_p(File.join(tmp_root, "app/views/rendering"))
    FileUtils.mkdir_p(File.join(tmp_root, "app/views/shared"))
    File.write(File.join(tmp_root, "app/views/rendering/show.html.erb"), "show-body")
    File.write(File.join(tmp_root, "app/views/rendering/show_locals.html.erb"), "hello, <%= greeting %>")
    File.write(File.join(tmp_root, "app/views/shared/notice.html.erb"), "shared-notice")
  end
end

RSpec.describe "Controller v2" do
  include Rack::Test::Methods
  include ControllerSpecAppBuilder

  around do |example|
    Dir.mktmpdir do |tmp|
      Dir.chdir(tmp) do
        make_views(tmp)
        example.run
      end
    end
  end

  describe "render" do
    let(:app) do
      build_app do
        get "/show",            "rendering#show"
        get "/show-locals",     "rendering#show_locals"
        get "/plain",           "rendering#plain"
        get "/html",            "rendering#html"
        get "/json",            "rendering#json"
        get "/custom",          "rendering#custom_status"
        get "/symbolic",        "rendering#symbolic_status"
        get "/absolute",        "rendering#absolute_template"
        get "/double",          "rendering#double_render"
        get "/missing",         "rendering#missing_template"
      end
    end

    it "looks up the matching template and returns 200 / text/html" do
      get "/show"
      expect(last_response.status).to eq(200)
      expect(last_response.headers["content-type"]).to include("text/html")
      expect(last_response.body).to eq("show-body")
    end

    it "render plain: returns text/plain with the body" do
      get "/plain"
      expect(last_response.headers["content-type"]).to include("text/plain")
      expect(last_response.body).to eq("x")
    end

    it "render html: returns text/html with the raw body" do
      get "/html"
      expect(last_response.headers["content-type"]).to include("text/html")
      expect(last_response.body).to eq("<p>raw</p>")
    end

    it "render json: returns application/json with serialized JSON" do
      get "/json"
      expect(last_response.headers["content-type"]).to include("application/json")
      expect(JSON.parse(last_response.body)).to eq("ok" => true)
    end

    it "render :show, status: 201 and status: :created both produce 201" do
      get "/custom"
      expect(last_response.status).to eq(201)
      get "/symbolic"
      expect(last_response.status).to eq(201)
    end

    it "render template: looks up the absolute path" do
      get "/absolute"
      expect(last_response.body).to eq("shared-notice")
    end

    it "render :show, locals: makes the local available in the template" do
      get "/show-locals"
      expect(last_response.body).to eq("hello, hi")
    end

    it "calling render twice raises Reins::DoubleResponse" do
      expect { get "/double" }.to raise_error(Reins::DoubleResponse)
    end

    it "auto-renders the action's default view when render is not called" do
      get "/show"
      expect(last_response.body).to eq("show-body")
    end

    it "raises Reins::MissingTemplate when the auto-render target is absent" do
      expect { get "/missing" }.to raise_error(Reins::MissingTemplate, /missing_template/)
    end
  end

  describe "redirect_to" do
    let(:app) do
      build_app do
        get "/go", "redirecting#go"
        get "/go-moved", "redirecting#go_moved"
        get "/double", "redirecting#double"
      end
    end

    it "sets Location and 302" do
      get "/go"
      expect(last_response.status).to eq(302)
      expect(last_response.headers["location"] || last_response.headers["Location"]).to eq("/login")
    end

    it "honors status: :moved_permanently as 301" do
      get "/go-moved"
      expect(last_response.status).to eq(301)
    end

    it "raises Reins::DoubleResponse when redirect_to follows render" do
      expect { get "/double" }.to raise_error(Reins::DoubleResponse)
    end
  end

  describe "head" do
    let(:app) do
      build_app do
        get "/empty",        "head_action#empty"
        get "/with-headers", "head_action#with_headers"
      end
    end

    it "head :no_content returns 204 with empty body" do
      get "/empty"
      expect(last_response.status).to eq(204)
      expect(last_response.body).to eq("")
    end

    it "head :unauthorized, retry_after: 60 returns 401 with the extra header" do
      get "/with-headers"
      expect(last_response.status).to eq(401)
      retry_after = last_response.headers["retry-after"] || last_response.headers["Retry-After"]
      expect(retry_after).to eq("60")
    end
  end

  describe "respond_to" do
    let(:app) do
      build_app do
        get "/show",      "responding#show"
        get "/html-only", "responding#html_only"
      end
    end

    it "dispatches to the html block for Accept: text/html" do
      header "Accept", "text/html"
      get "/show"
      expect(last_response.body).to eq("html-body")
    end

    it "dispatches to the json block for Accept: application/json" do
      header "Accept", "application/json"
      get "/show"
      expect(JSON.parse(last_response.body)).to eq("fmt" => "json")
    end

    it "dispatches to the first registered block for Accept: */*" do
      header "Accept", "*/*"
      get "/show"
      expect(last_response.body).to eq("html-body")
    end

    it "returns 406 when no registered block matches the Accept header" do
      header "Accept", "application/json"
      get "/html-only"
      expect(last_response.status).to eq(406)
    end
  end

  describe "session" do
    let(:app) do
      build_app_with_session do
        get "/sess/write", "sessions#write"
        get "/sess/read",  "sessions#read"
      end
    end

    let(:app_no_session) do
      build_app do
        get "/sess/read", "sessions#read"
      end
    end

    it "session[:k] = v writes through to env['rack.session']" do
      get "/sess/write"
      get "/sess/read"
      expect(last_response.body).to eq('session.foo="bar"')
    end

    it "raises Reins::SessionMiddlewareMissing when the rack session middleware is absent" do
      old_app = @app
      @app = nil
      # noop, see below
      reins_app = build_app do
        get "/sess/read", "sessions#read"
      end
      env = Rack::MockRequest.env_for("/sess/read")
      expect { reins_app.call(env) }.to raise_error(Reins::SessionMiddlewareMissing)
    ensure
      @app = old_app if old_app
    end
  end

  describe "filters" do
    before do
      FilterParentController::CALLS.clear
      FilterChildController::CALLS.clear
      HaltingController::CALLS.clear
    end

    let(:filter_app) do
      build_app do
        get "/idx",    "filter_child#index"
        get "/bare",   "filter_child#bare"
        get "/scoped", "filter_child#scoped_action"
      end
    end

    let(:halt_app) do
      build_app do
        get "/halt", "halting#index"
      end
    end

    it "before_action runs before the action body" do
      def app = filter_app
      get "/idx"
      calls = FilterChildController::CALLS
      expect(calls.index(:p_before)).to be < calls.index(:index)
      expect(calls.index(:c_before)).to be < calls.index(:index)
    end

    it "after_action runs after the action body" do
      def app = filter_app
      get "/idx"
      calls = FilterChildController::CALLS
      expect(calls.index(:index)).to be < calls.index(:p_after)
    end

    it "before_action :only filters which actions trigger the callback" do
      def app = filter_app
      get "/scoped"
      expect(FilterChildController::CALLS).to include(:scoped)

      FilterChildController::CALLS.clear
      get "/idx"
      expect(FilterChildController::CALLS).not_to include(:scoped)
    end

    it "before_action :except skips the listed actions" do
      def app = filter_app
      get "/bare"
      expect(FilterChildController::CALLS).not_to include(:unscoped)

      FilterChildController::CALLS.clear
      get "/idx"
      expect(FilterChildController::CALLS).to include(:unscoped)
    end

    it "around_action wraps the action — before yield, then action, then after yield" do
      def app = filter_app
      get "/idx"
      expect(FilterChildController::CALLS).to include(:wrap_in, :index, :wrap_out)
      expect(FilterChildController::CALLS.index(:wrap_in)).to be < FilterChildController::CALLS.index(:index)
      expect(FilterChildController::CALLS.index(:index)).to be < FilterChildController::CALLS.index(:wrap_out)
    end

    it "filters declared on a parent class are inherited by the subclass" do
      def app = filter_app
      get "/idx"
      expect(FilterChildController::CALLS).to include(:p_before, :p_after)
    end

    it "a before_action that emits a response halts the chain" do
      def app = halt_app
      get "/halt"
      expect(last_response.status).to eq(302)
      expect(HaltingController::CALLS).to eq([:gatekeeper])
    end
  end
end
