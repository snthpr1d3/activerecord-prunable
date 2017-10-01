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

      def prune!(*params, prune_method: nil)
        logger.info "Pruning old records of #{self}"
        return false unless check_scope(*params)

        scope = prunable(*params)
        destroyed_records = prune_by_method(scope, prune_method)

        if destroyed_records.positive?
          logger.info "#{destroyed_records} records have been removed."
        else
          logger.info 'Nothing to prune.'
        end

        destroyed_records
      end

      private

      def check_scope(*params)
        unless respond_to?(:prunable)
          logger.info "The model hasn't got prunable scope, action is not allowed."
          return false
        end

        unless prunable(*params).is_a?(::ActiveRecord::Relation)
          logger.info 'Model.prunable is not a relation, action is not allowed.'
          return false
        end

        true
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
