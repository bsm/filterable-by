require 'active_record'
require 'active_support/concern'
require 'set'

module ActiveRecord
  module FilterableByHelper
    extend ActiveSupport::Concern

    def self.normalize(value)
      case value
      when String, Numeric
        value
      when Array
        value.select { |v| normalize(v) }
      end
    end

    included do
      class_attribute :_filterable_by_scope_options, instance_accessor: false
      self._filterable_by_scope_options = {}
    end

    module ClassMethods

      def filterable_by(*names, &block)
        names.each do |name|
          _filterable_by_scope_options[name.to_s] = block || ->(scope, v) { scope.where(name.to_sym => v) }
        end
      end

      # @param [Hash] hash the filter params
      # @return [ActiveRecord::Relation] the scoped relation
      def filter_by(hash)
        scope = all
        return scope unless hash.is_a?(Hash)

        _filterable_by_scope_options.each do |name, block|
          next unless hash.key?(name)

          value = FilterableByHelper.normalize(hash[name])
          next if value.blank?

          scope = block.call(scope, value)
        end
        scope
      end

    end
  end

  class Base
    include FilterableByHelper
  end
end
