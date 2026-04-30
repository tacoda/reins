module Reins
  class Error < StandardError; end
  class DoubleResponse < Error; end
  class MissingTemplate < Error; end
  class ParameterMissing < Error; end
  class SessionMiddlewareMissing < Error; end
end
