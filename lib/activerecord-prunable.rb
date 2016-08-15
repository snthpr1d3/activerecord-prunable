require 'active_record/prunable'

module Prunable
  @@eager_load = nil

  class << self
    def models
      @@eager_load ||= Rails.application.eager_load!
      ActiveRecord::Prunable.includes
    end

    def prune!(*models, prune_method: nil)
      models = self.models if models.empty?
      models.each do |model|
        if prune_method && !model.class_variable_defined?(:@@prune_method)
          model.prune_method(prune_method)
        end

        model.prune!
      end
    end
  end
end
