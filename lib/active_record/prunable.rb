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
        unless check_prune_method(method)
          logger.info "Incorrect prune method #{method} has been ignored for #{self}"
          return false
        end

        logger.info "Prune method #{method} has been set for #{self}"
        class_variable_set(:@@prune_method, method)
      end

      def prune_after(duration)
        prune_created_after(duration)
      end

      def prune_created_after(duration)
        class_variable_set(:@@prune_created_after, duration)
      end

      def prune_updated_after(duration)
        class_variable_set(:@@prune_updated_after, duration)
      end

      def prune!(*params, prune_method: nil, current_time: nil)
        logger.info "Pruning old records of #{self}"
        return false unless check_scope(*params)

        scope = resolve_scope(*params, current_time)
        destroyed_records = prune_by_method(scope, prune_method)

        if destroyed_records > 0
          logger.info "#{destroyed_records} records have been removed."
        else
          logger.info 'Nothing to prune.'
        end

        destroyed_records
      end

      private

      def check_scope(*params)
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

        case
        when respond_to?(:prunable)
          prunable(*params)
        when class_variable_defined?(:@@prune_created_after)
          where('created_at < ?', current_time - class_variable_get(:@@prune_created_after))
        when class_variable_defined?(:@@prune_updated_after)
          where('updated_at < ?', current_time - class_variable_get(:@@prune_updated_after))
        end
      end

      def check_prune_method(method)
        %i[destroy delete].include?(method)
      end

      def prune_by_method(scope, prune_method)
        prune_method = if class_variable_defined?(:@@prune_method)
                         class_variable_get(:@@prune_method)
                       else
                         prune_method || :destroy
                       end

        return false unless check_prune_method(prune_method)

        logger.info "Prune method is #{prune_method}"

        return scope.delete_all if prune_method == :delete
        scope.destroy_all.size
      end
    end
  end
end
