module Reins
  class Env < String
    def development? = self == "development"
    def test?        = self == "test"
    def production?  = self == "production"
  end
end
