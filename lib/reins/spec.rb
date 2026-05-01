require "reins/spec/matchers"
require "reins/spec/model"
require "reins/spec/controller"
require "reins/spec/integration"
require "reins/spec/fixtures"

RSpec.configure do |config|
  config.include Reins::Spec::Matchers
  config.include Reins::Spec::Model,       type: :model
  config.include Reins::Spec::Controller,  type: :controller
  config.include Reins::Spec::Integration, type: :integration
end
