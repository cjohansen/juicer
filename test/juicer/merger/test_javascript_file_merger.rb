require File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. test_helper])) unless defined?(Juicer)

class TestJavaScriptFileMerger < Test::Unit::TestCase

  def setup
    @file_merger = Juicer::Merger::JavaScriptFileMerger.new
    @file_setup = Juicer::Test::FileSetup.new($DATA_DIR)
    @file_setup.create!
  end

  def teardown
    file = File.join($DATA_DIR, 'test_out.js')
    File.delete(file) if File.exists?(file)
  end

  def test_init
    Juicer::Merger::JavaScriptFileMerger.publicize_methods do
      assert_equal Juicer::Merger::JavaScriptDependencyResolver, @file_merger.dependency_resolver.class
    end
  end

  def test_merge
    Juicer::Merger::JavaScriptFileMerger.publicize_methods do
      a_content = <<EOF
/**
 * @depend b.js
 */

/* Dette er a.js */

EOF
      content = @file_merger.merge(File.join($DATA_DIR, 'a.js'))
      assert_equal a_content, content
    end
  end

  def test_constructor
    file_merger = Juicer::Merger::JavaScriptFileMerger.new(File.join($DATA_DIR, 'a.js'))
    assert_equal 2, file_merger.files.length
  end

  def test_append
    @file_merger << File.join($DATA_DIR, 'a.js')
    assert_equal 2, @file_merger.files.length
  end

  def test_save
    a_js = File.join($DATA_DIR, 'a.js')
    b_js = File.join($DATA_DIR, 'b.js')
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
    contents = @file_merger.save
    assert_equal merged, contents

    contents = nil
    output_file = File.join($DATA_DIR, 'test_out.js')
    assert_not_equal merged, contents
    assert @file_merger.save(output_file)

    assert_equal merged, IO.read(output_file)
  end
end
