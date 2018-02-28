# frozen_string_literal: true

require 'active_record/prunable'

module Prunable
  @@eager_load = nil

  class << self
    def models
      @@eager_load ||= Rails.application.eager_load!
      ActiveRecord::Prunable.includes
    end

    def prune!(*args)
      models, params = resolve_args(args)

      models.each_with_object({}) do |model, pruned|
        pruned[model.table_name] = prune_model!(model, params)
      end
    end

    def prune(*args)
      models, params = resolve_args(args)

      pruned = {}
      errors = []

      models.each do |model|
        begin
          pruned[model.table_name] = prune_model!(model, params)
        rescue StandardError => e
          errors << e
        end
      end

      [pruned, errors]
    end

    private

    def resolve_args(args)
      params = args.last.is_a?(Hash) ? args.pop : {}
      models = args.any? ? args : self.models
      [models, params]
    end

    def prune_model!(model, prune_method: nil, current_time: nil, params: [], batch_size: nil, in_batches: false)
      model.prune!(
        *params,
        prune_method: prune_method,
        current_time: current_time,
        batch_size: batch_size,
        in_batches: in_batches
      )
    end
  end
end
