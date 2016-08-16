$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'activerecord-prunable'
require 'byebug'

class SomeMixin < ActiveRecord::Base
  include ActiveRecord::Prunable
end

class AnotherMixin < ActiveRecord::Base
  include ActiveRecord::Prunable
end

class FakeActiveRecord < ActiveRecord::Base
end

class Logger
  def self.info(_message)
  end
end

class Rails
  @@app = nil

  class << self
    def application
      @@app ||= Application.new
    end
  end
end

class Application
  def eager_load!
    []
  end
end
