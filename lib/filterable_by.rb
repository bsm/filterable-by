require 'active_record'
require 'active_support/concern'
require 'set'

module ActiveRecord
  module FilterableBy
    def self.normalize(value)
      case value
      when String, Numeric
        value
      when Array
        value.select {|v| normalize(v) }
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
        names.each do |name|
          _filterable_by_config[name.to_s] = block || ->(scope, value, **) { scope.where(name.to_sym => value) }
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
          next unless hash.key?(name)

          value = FilterableBy.normalize(hash[name])
          next if value.blank?

          scope = block.call(scope, value, **opts)
        end

        scope || none
      end
    end
  end

  class Base
    extend FilterableBy::ClassMethods
  end
end
