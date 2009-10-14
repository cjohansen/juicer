require "test_helper"

class TestSymbolExtensions < Test::Unit::TestCase
  context "camel case method" do
    should "return camel cased string from underscored symbol" do
      assert_equal "CamelCase", :camel_case.camel_case
    end

    should "return camel cased string from upper cased underscored symbol" do
      assert_equal "CamelCase", :CAMEL_CASE.camel_case
    end

    should "return camel cased string from 'camel cased' underscored symbol" do
      assert_equal "CamelCase", :Camel_Case.camel_case
    end
  end

  context "classify method" do
    should "return nested class" do
      assert_equal Juicer::DependencyResolver, :dependency_resolver.classify(Juicer)
    end

    should "return top level class from underscored symbol" do
      assert_equal FileUtils, :file_utils.classify
    end
  end
end
