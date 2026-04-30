require "logger"
require "fileutils"

module Reins
  module LoggerFactory
    def self.build(path:, level:)
      FileUtils.mkdir_p(File.dirname(path))
      logger = ::Logger.new(path)
      logger.level = level_value(level)
      logger
    end

    def self.level_value(level)
      case level
      when Symbol then ::Logger.const_get(level.to_s.upcase)
      else level
      end
    end
  end
end
