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
      def prune!
        logger.info "Pruning old records of #{self}"

        unless respond_to?(:prunable)
          logger.info "This model has no :prunable scope, nothing to prune."
          return
        end

        unless prunable.is_a?(::ActiveRecord::Relation)
          logger.info ":prunable is not a relation, nothing to prune."
          return
        end

        destroyed = prunable.destroy_all

        if destroyed.any?
          logger.info "#{destroyed.size} records have been pruned."
        else
          logger.info "Nothing to prune."
        end

        destroyed
      end
    end
  end
end
