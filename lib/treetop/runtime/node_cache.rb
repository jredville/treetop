module Treetop
  module Runtime
    class NodeCache
      attr_reader :results
      
      def initialize
        @node_index = Hash.new {|h, k| h[k] = Hash.new }
        @terminal_results = []
        @results = []
      end

      def store(rule_name, result, additional_dependencies = [])
        memoization = Memoization.new(rule_name, result, node_index)
        memoization.dependencies = [result] + additional_dependencies
        memoization.dependencies.each do |dependency|
          register_result(dependency)
          dependency.memoizations.push(memoization)
        end
      end

      def get(rule_name, start_index)
        node_index[rule_name][start_index]
      end

      def has_result?(rule_name, start_index)
        node_index[rule_name].has_key?(start_index)
      end

      def expire(range, length_change)
        @results_to_delete = []
        @memoizations_to_expire = []

        results.each do |result|
          result.expire if result.interval.intersects?(range)
        end

        @results -= results_to_delete
        memoizations_to_expire.uniq.each do |memoization|
          memoization.expire
        end

        results.each do |result|
          result.relocate(length_change) if result.interval.first >= range.last
        end
      end

      def schedule_memoization_expiration(memoization)
        memoizations_to_expire.push(memoization)
      end

      def schedule_result_deletion(result)
        results_to_delete.push(result)
      end

      protected
      
      def register_result(result)
        return if result.registered?
        result.node_cache = self
        result.dependencies.each do |subresult|
          subresult.dependents.push(result)
          register_result(subresult)
        end
        result.registered = true
        results.push(result)
      end
      
      attr_reader :node_index, :results_to_delete, :memoizations_to_expire
    end
  end
end