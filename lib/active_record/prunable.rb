# frozen_string_literal: true

require 'active_support'
require 'active_record'

module ActiveRecord
  module Prunable
    extend ActiveSupport::Concern

    @@models = []

    class << self
      def included(model)
        @@models << model
      end

      def includes
        @@models
      end
    end

    module ClassMethods
      def prune_method(method)
        unless valid_prune_method?(method)
          logger.info "Incorrect prune method #{method} has been ignored for #{self}"
          return false
        end

        logger.info "Prune method #{method} has been set for #{self}"
        class_variable_set(:@@prune_method, method)
      end

      def prune_created_after(duration, batch_removal: nil, remove_in_batches: nil)
        class_variable_set(:@@prune_created_after, duration)

        batch_removal_arg = batch_removal || remove_in_batches
        batch_removal(batch_removal_arg) if batch_removal_arg
      end

      alias prune_after prune_created_after

      def prune_updated_after(duration, batch_removal: nil, remove_in_batches: nil)
        class_variable_set(:@@prune_updated_after, duration)

        batch_removal_arg = batch_removal || remove_in_batches
        batch_removal(batch_removal_arg) if batch_removal_arg
      end

      def prune!(*params, prune_method: nil, current_time: nil, batch_size: nil, in_batches: false)
        logger.info "Pruning old records of #{self}"
        return false unless prunable_model?

        scope = resolve_scope(*params, current_time)
        batch_size ||= class_variable_get(:@@prunable_batch_size) if class_variable_defined?(:@@prunable_batch_size)
        batch_size ||= 1000 if in_batches
        destroyed_records = prune(scope, prune_method, batch_size)

        if destroyed_records.zero?
          logger.info 'Nothing to prune.'
        else
          logger.info "#{destroyed_records} records have been removed."
        end

        destroyed_records
      end

      def batch_removal(batch_size = nil)
        batch_size = 1000 unless batch_size.is_a?(Integer)
        class_variable_set(:@@prunable_batch_size, batch_size)
      end
      alias remove_in_batches batch_removal

      private

      def prunable_model?
        pruning_means_count = [
          respond_to?(:prunable),
          class_variable_defined?(:@@prune_created_after),
          class_variable_defined?(:@@prune_updated_after)
        ].count(true)

        if pruning_means_count.zero?
          logger.info "The model hasn't got prunable scope or TTL, action is not allowed."
          return false
        end

        if pruning_means_count > 1
          logger.info 'Ambiguity detected, action is not allowed.'
          return false
        end

        true
      end

      def resolve_scope(*params, current_time)
        current_time ||= Time.current

        if respond_to?(:prunable)
          prunable(*params)
        elsif class_variable_defined?(:@@prune_created_after)
          where('created_at < ?', current_time - class_variable_get(:@@prune_created_after))
        elsif class_variable_defined?(:@@prune_updated_after)
          where('updated_at < ?', current_time - class_variable_get(:@@prune_updated_after))
        end
      end

      def valid_prune_method?(method)
        %i[destroy delete].include?(method)
      end

      def prune(scope, prune_method, batch_size)
        prune_method = resolve_prune_method(prune_method)
        return false unless valid_prune_method?(prune_method)

        logger.info "Prune method is #{prune_method}"

        pruner = pruner_for(prune_method)
        return pruner.call(scope) unless batch_size

        logger.info "Removing in batches, batch_size: #{batch_size}"

        batch_results = scope.find_in_batches(batch_size: batch_size) do |batch|
          batch_ids = batch.map(&:id)
          relation = scope.model.where(id: batch_ids)
          pruner.call(relation)
        end

        batch_results.present? ? batch_results.sum : 0
      end

      def resolve_prune_method(prune_method)
        return class_variable_get(:@@prune_method) if class_variable_defined?(:@@prune_method)
        prune_method || :destroy
      end

      def pruner_for(prune_method)
        if prune_method == :delete
          :delete_all.to_proc
        else
          ->(scope) { scope.destroy_all.size }
        end
      end
    end
  end
end
