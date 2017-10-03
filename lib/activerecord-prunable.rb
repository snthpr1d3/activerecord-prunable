# frozen_string_literal: true

require 'active_record/prunable'

module Prunable
  @@eager_load = nil

  class << self
    def models
      @@eager_load ||= Rails.application.eager_load!
      ActiveRecord::Prunable.includes
    end

    def prune!(*models, prune_method: nil, current_time: nil, params: [])
      models = self.models if models.empty?

      models.each do |model|
        model.prune!(*params, prune_method: prune_method, current_time: current_time)
      end
    end
  end
end
