require 'active_record/prunable'

module Prunable
  @@eager_load = nil

  class << self
    def models
      @@eager_load ||= Rails.application.eager_load!
      ActiveRecord::Prunable.includes
    end

    def prune!(*models)
      models = self.models if models.empty?
      models.each(&:prune!)
    end
  end
end
