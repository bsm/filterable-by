require 'active_record'
require 'active_support/concern'
require 'set'

module ActiveRecord
  module FilterableBy
    class << self
      def normalize(value)
        case value
        when String, Numeric
          value
        when Array
          value.select {|v| normalize(v) }
        end
      end

      def merge(scope, unscoped, hash, name, **opts, &block)
        key = name
        positive = normalize(hash[key]) if hash.key?(key)
        if positive.present?
          sub = eval_scope(scope, unscoped, positive, **opts, &block)
          return nil unless sub

          scope = scope.merge(sub)
        end

        key = "#{name}_not"
        negative = normalize(hash[key]) if hash.key?(key)
        if negative.present?
          sub = eval_scope(scope, unscoped, negative, **opts, &block)
          return nil unless sub

          scope = scope.merge(invert_where(sub))
        end

        scope
      end

      private

      def eval_scope(scope, unscoped, value, **opts, &block)
        if block.arity == 2
          scope.instance_exec(unscoped, value, **opts, &block)
        else
          scope.instance_exec(value, **opts, &block)
        end
      end

      def invert_where(scope)
        if scope.respond_to?(:invert_where!)
          scope.invert_where!
        else
          scope.where_clause = scope.where_clause.invert
        end
        scope
      end
    end

    module ClassMethods
      def self.extended(base) # :nodoc:
        base.class_attribute :_filterable_by_config, instance_accessor: false, instance_predicate: false
        base._filterable_by_config = {}
        super
      end

      def inherited(base) # :nodoc:
        base._filterable_by_config = _filterable_by_config.deep_dup
        super
      end

      def filterable_by(*names, &block)
        if block && block.arity > 1
          ActiveSupport::Deprecation.warn('using scope in filterable_by blocks is deprecated. Please use filterable_by(:x) {|val| where(field: val) } instead.')
        end

        names.each do |name|
          _filterable_by_config[name.to_s] = block || ->(value, **) { where(name.to_sym => value) }
        end
      end

      # @param [Hash|ActionController::Parameters] the filter params
      # @return [ActiveRecord::Relation] the scoped relation
      def filter_by(hash = nil, **opts)
        if hash.nil?
          hash = opts
          opts = {}
        end

        scope = all
        return scope unless hash.respond_to?(:key?) && hash.respond_to?(:[])

        _filterable_by_config.each do |name, block|
          scope = FilterableBy.merge(scope, unscoped, hash, name, **opts, &block)
          break unless scope
        end

        scope || none
      end
    end
  end

  class Base
    extend FilterableBy::ClassMethods
  end
end
