require "test_helper"

class TestJavaScriptMerger < Test::Unit::TestCase

  def setup
    @file_merger = Juicer::Merger::JavaScriptMerger.new
    Juicer::Test::FileSetup.new.create
  end

  def teardown
    file = path('test_out.js')
    File.delete(file) if File.exists?(file)
  end

  def test_init
    Juicer::Merger::JavaScriptMerger.publicize_methods do
      assert_equal Juicer::JavaScriptDependencyResolver, @file_merger.dependency_resolver.class
    end
  end

  def test_merge
    Juicer::Merger::JavaScriptMerger.publicize_methods do
      a_content = <<EOF
/**
 * @depend b.js
 */

/* Dette er a.js */

EOF
      content = @file_merger.merge(path('a.js'))
      assert_equal a_content, content
    end
  end

  def test_constructor
    file_merger = Juicer::Merger::JavaScriptMerger.new(path('a.js'))
    assert_equal 2, file_merger.files.length
  end

  def test_append
    @file_merger << path('a.js')
    assert_equal 2, @file_merger.files.length
  end

  def test_save
    a_js = path('a.js')
    b_js = path('b.js')
    merged = <<EOF
/**
 * @depends a.js
 */

/* Dette er b.css */

/**
 * @depend b.js
 */

/* Dette er a.js */

EOF

    @file_merger << a_js
    ios = StringIO.new
    @file_merger.save(ios)
    assert_equal merged, ios.string

    output_file = path('test_out.js')
    @file_merger.save(output_file)

    assert_equal merged, IO.read(output_file)
  end
end
