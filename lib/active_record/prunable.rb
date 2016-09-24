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
        return false unless check_prune_method(method)

        logger.info "Prune method #{method} has been set for #{self}"
        class_variable_set(:@@prune_method, method)
      end

      def prune!(*params, prune_method: nil)
        logger.info "Pruning old records of #{self}"
        return false unless check_scope(*params)

        scope = prunable(*params)
        destroyed = prune_by_method(scope, prune_method)

        if destroyed > 0
          logger.info "#{destroyed} records have been pruned."
        else
          logger.info "Nothing to prune."
        end

        destroyed
      end

      private

      def check_scope(*params)
        unless respond_to?(:prunable)
          logger.info "This model has no :prunable scope, nothing to prune."
          return false
        end

        unless prunable(*params).is_a?(::ActiveRecord::Relation)
          logger.info ":prunable is not a relation, nothing to prune."
          return false
        end

        true
      end

      def check_prune_method(method)
        unless [:destroy, :delete].include?(method)
          logger.info "Incorrect prune method #{method} will be ignored for #{self}"
          return false
        end
        true
      end

      def prune_by_method(scope, prune_method)
        unless class_variable_defined?(:@@prune_method)
          prune_method = prune_method || :destroy
        else
          prune_method = class_variable_get(:@@prune_method)
        end

        return false unless check_prune_method(prune_method)

        logger.info "Prune method is #{prune_method}"

        if prune_method == :delete
          scope.delete_all
        else
          scope.destroy_all.size
        end
      end
    end
  end
end
