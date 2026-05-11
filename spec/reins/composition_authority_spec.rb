require "spec_helper"

RSpec.describe "composition root authority" do
  before do
    Reins::Application.instances.clear
    Reins::Model::Base.reset_adapters!
  end

  after do
    Reins::Application.instances.clear
    Reins::Model::Base.reset_adapters!
  end

  describe "Reins.current_application" do
    it "returns nil when no Application has been constructed" do
      expect(Reins.current_application).to be_nil
    end

    it "returns the most-recent Application after one has been constructed" do
      app = Reins::Application.new(profile: :slim)
      expect(Reins.current_application).to be(app)
    end
  end

  describe "Reins::Model::Base.repository" do
    it "falls back to the SQLite default when no Application has been constructed" do
      expect(Reins::Model::Base.repository).to be_a(Reins::Adapters::Driven::Sqlite::Repository)
    end

    it "uses the Application's adapter when one is wired" do
      Reins::Application.new(profile: :test)
      expect(Reins::Model::Base.repository).to be_a(Reins::Adapters::Driven::Memory::Repository)
    end

    it "explicit per-class override wins over the Application's adapter" do
      Reins::Application.new(profile: :test)
      override = Reins::Adapters::Driven::Memory::Repository.new
      Reins::Model::Base.repository = override
      expect(Reins::Model::Base.repository).to be(override)
    end
  end

  describe "Reins::Model::Base.schema_inspector" do
    it "falls back to the SQLite default with no application" do
      expect(Reins::Model::Base.schema_inspector).to be_a(Reins::Adapters::Driven::Sqlite::SchemaInspector)
    end

    it "uses the Application's adapter when one is wired" do
      Reins::Application.new(profile: :test)
      expect(Reins::Model::Base.schema_inspector).to be_a(Reins::Adapters::Driven::Memory::SchemaInspector)
    end
  end

  describe "Reins::Model::Base.schema_migrator" do
    it "falls back to the SQLite default with no application" do
      expect(Reins::Model::Base.schema_migrator).to be_a(Reins::Adapters::Driven::Sqlite::SchemaMigrator)
    end
  end

  describe "Reins::View.new" do
    it "uses the Application's template_store and template_engine when present" do
      memory_store = Reins::Adapters::Driven::Memory::TemplateStore.new("a/b" => "ok")
      Reins::Application.new(profile: :slim, adapters: {
                               template_store: memory_store,
                               template_engine: Reins::Adapters::Driven::Erubis::TemplateEngine.new
                             }, validate: false)

      view = Reins::View.new
      expect(view.template_store).to be(memory_store)
    end

    it "falls back to Filesystem + Erubis when no application has been constructed" do
      view = Reins::View.new
      expect(view.template_store).to be_a(Reins::Adapters::Driven::Filesystem::TemplateStore)
      expect(view.template_engine).to be_a(Reins::Adapters::Driven::Erubis::TemplateEngine)
    end
  end
end
