require File.join(File.dirname(__FILE__), '..', 'test_helper')
require 'benchmark'

class CircularCompilationTest < CompilerTestCase
  test "the generated metagrammar parser can parse the treetop file whence it came" do
    File.open(METAGRAMMAR_2_PATH, 'r') do |file|
      input = file.read
      
      # Benchmark.bm(1) do |x|
      #   x.report("parsing metagrammar") do
      #     parser.parse(input)
      #   end
      # end
      
      result = parse_with_metagrammar_2(input, :grammar)
      result.should be_success
      lambda { result.compile }.should_not raise_error
    end
  end
end