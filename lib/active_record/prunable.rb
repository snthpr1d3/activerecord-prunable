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
        unless [:destroy, :delete].include?(method)
          logger.info "Incorrect prune method #{method} will be ignored"
          return false
        end

        logger.info "Prune method #{method} was successfully setted"
        class_variable_set(:@@prune_method, method)
      end

      def prune!
        logger.info "Pruning old records of #{self}"
        return false unless check_scope

        destroyed = prune_by_method

        if destroyed > 0
          logger.info "#{destroyed} records have been pruned."
        else
          logger.info "Nothing to prune."
        end

        destroyed
      end

      private

      def check_scope
        unless respond_to?(:prunable)
          logger.info "This model has no :prunable scope, nothing to prune."
          return false
        end

        unless prunable.is_a?(::ActiveRecord::Relation)
          logger.info ":prunable is not a relation, nothing to prune."
          return false
        end

        true
      end

      def prune_by_method
        unless class_variable_defined?(:@@prune_method)
          prune_method = :destroy
        else
          prune_method = class_variable_get(:@@prune_method)
        end

        logger.info "Prune method is #{prune_method}"

        if prune_method == :delete
          prunable.delete_all
        else
          prunable.destroy_all.size
        end
      end
    end
  end
end
