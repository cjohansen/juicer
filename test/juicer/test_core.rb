require File.expand_path(File.join(File.dirname(__FILE__), %w[.. test_helper])) unless defined?(Juicer)

class TestStringExtensions < Test::Unit::TestCase
  def test_camel_case
    assert_equal "CamelCase", "camel_case".camel_case
    assert_equal "Camel case", "camel case".camel_case
    assert_equal "CamelCase", "CAMEL_CASE".camel_case
    assert_equal "CamelCase", "Camel_Case".camel_case
  end

  def test_to_class
    assert_equal String, "String".to_class

    assert_raise RuntimeError do
      "String".to_class(Array)
    end

    assert_equal String, "String".to_class(Object)
    assert_equal Juicer::Merger, "Juicer::Merger".to_class
    assert_equal Juicer::Merger, "Merger".to_class(Juicer)
    assert_equal Juicer::Merger::StylesheetMerger, "Juicer::Merger::StylesheetMerger".to_class
    assert_equal Juicer::Merger::StylesheetMerger, "StylesheetMerger".to_class(Juicer::Merger)
  end

  def test_classify
    assert_equal Juicer::Merger, "merger".classify(Juicer)
    assert_equal FileUtils, "file_utils".classify
  end

  def test_underscore
    assert_equal "stylesheet_merger", "StylesheetMerger".underscore
  end
end

class TestSymbolExtensions < Test::Unit::TestCase
  def test_camel_case
    assert_equal "CamelCase", :camel_case.camel_case
    assert_equal "CamelCase", :camel_case.camel_case
    assert_equal "CamelCase", :CAMEL_CASE.camel_case
    assert_equal "CamelCase", :Camel_Case.camel_case
  end

  def test_classify
    assert_equal Juicer::Merger, :merger.classify(Juicer)
    assert_equal FileUtils, :file_utils.classify
  end
end
