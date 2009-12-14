require "test_helper"

class TestStringExtensions < Test::Unit::TestCase
  context "camel case method" do
    should "convert underscored string" do
      assert_equal "CamelCase", "camel_case".camel_case
    end

    should "convert spaced string" do
      assert_equal "Camel case", "camel case".camel_case
    end

    should "convert upper-case underscored string" do
      assert_equal "CamelCase", "CAMEL_CASE".camel_case
    end

    should "convert 'camel cased' underscored string" do
      assert_equal "CamelCase", "Camel_Case".camel_case
    end
  end

  context "to_class method" do
    should "return String class" do
      assert_equal String, "String".to_class
    end

    should "return String class from Object" do
      assert_equal String, "String".to_class(Object)
    end

    should "return nested class" do
      assert_equal Juicer::DependencyResolver, "Juicer::DependencyResolver".to_class
    end

    should "return class from module" do
      assert_equal Juicer::DependencyResolver, "DependencyResolver".to_class(Juicer)
    end

    should "return class from nested module" do
      assert_equal Juicer::Install::YuiCompressorInstaller, "YuiCompressorInstaller".to_class(Juicer::Install)
    end
  end

  context "classify method" do
    should "return class from underscored string" do
      assert_equal Juicer::DependencyResolver, "dependency_resolver".classify(Juicer)
    end

    should "return top level class from underscored string" do
      assert_equal FileUtils, "file_utils".classify
    end
  end

  context "underscore method" do
    should "return underscored string from camel cased string" do
      assert_equal "stylesheet_merger", "StylesheetMerger".underscore
    end
  end
end
