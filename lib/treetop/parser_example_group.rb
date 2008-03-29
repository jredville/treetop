require 'rubygems'
require 'treetop'
require 'spec'

module Treetop
  # A custom RSpec example group which assists with the testing of the 
  # behaviors of the single rules rather than the default root. 
  # 
  # Using it as the default example group: 
  #    require 'treetop/parser_example_group'
  #    Spec::Example::ExampleGroupFactory.default(Treetop::ParserExampleGroup)
  # 
  # Using it for a subset of specs: 
  #    require 'treetop/parser_example_group'
  #    Spec::Example::ExampleGroupFactory.register(:my_parser, Treetop::ParserExampleGroup)
  class ParserExampleGroup < Spec::Example::ExampleGroup
    class << self
      attr_reader :default_klass, :default_root

      def parse_from(klass, root = nil)
        @default_klass, @default_root = klass, root
      end
    end

    attr_reader :parser

    def parse(input, options = {})
      @parser = (options[:klass] || self.class.default_klass).new
      if root = (options[:root] || self.class.default_root)
        parser.root = root
      end
      unless options[:consume_all_input].nil?
        parser.consume_all_input = options.delete(:consume_all_input)
      end
      result = parser.parse(input, options)
      yield result if block_given?
      result
    end

    class BeParsedAndEql
      def initialize(parser, value)
        @parser, @value = parser, value
      end

      def matches?(result)
        @result = result
        parsed? && correct_value?
      end

      def parsed?
        !@result.nil?
      end

      def correct_value?
        @result.value == @value
      end

      def failure_message
        unless parsed?
          "expected input to be parsed\nfailure_reason: #{@parser.failure_reason}"
        else
          "expected: #{@value.inspect},\n     got: #{@result.value.inspect}"
        end
      end

      def negative_failure_message
        if parsed?
          "expected input not to be parsed"
        end
      end
    end

    def be_parsed_and_eql(value)
      BeParsedAndEql.new(parser, value)
    end

    class HaveFailedParsingBecause
      def initialize(parser, failure_reason)
        @parser, @failure_reason = parser, failure_reason
      end

      def matches?(result)
        @target = result
        not_parsed? && correct_reason?
      end

      def not_parsed?
        @result.nil?
      end

      def correct_reason?
        @parser.failure_reason == @failure_reason
      end

      def failure_message
        if parsed?
          "expected input not to be parsed because #{@failure_message}"
        else
          "failure message was incorrect\nexpected: #{@failure_message},\n     got: #{@parser.failure_message}"
        end
      end

      def negative_failure_message
        raise RspecCommandError, "Cannot use this like so"
      end
    end

    def have_failed_parsing_because(failure_message)
      HaveFailedParsingBecause.new(parser, failure_message)
    end
  end
end