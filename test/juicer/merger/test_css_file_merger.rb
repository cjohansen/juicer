require File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. test_helper])) unless defined?(Juicer)

class TestCssFileMerger < Test::Unit::TestCase

  def setup
    @file_merger = Juicer::Merger::CssFileMerger.new
    @file_setup = Juicer::Test::FileSetup.new($DATA_DIR)
    @file_setup.create!
  end

  def teardown
    file = File.join($DATA_DIR, 'test_out.css')
    File.delete(file) if File.exists?(file)
  end

  def test_init
    Juicer::Merger::CssFileMerger.publicize_methods do
      assert_equal Juicer::Merger::CssImportResolver, @file_merger.dependency_resolver.class
    end
  end

  def test_merge
    Juicer::Merger::CssFileMerger.publicize_methods do
      a_content = "\n\n/* Dette er a.css */\n"
      content = @file_merger.merge(File.join($DATA_DIR, 'a.css'))
      assert_equal a_content + "\n", content
    end
  end

  def test_constructor
    file_merger = Juicer::Merger::CssFileMerger.new(File.join($DATA_DIR, 'a.css'))
    assert_equal 2, file_merger.files.length
  end

  def test_append
    @file_merger << File.join($DATA_DIR, 'a.css')
    assert_equal 2, @file_merger.files.length
  end

  def test_save
    a_css = File.join($DATA_DIR, 'a.css')
    b_css = File.join($DATA_DIR, 'b.css')
    merged = <<EOF
/* Dette er b.css */



/* Dette er a.css */

EOF

    @file_merger << a_css
    contents = @file_merger.save
    assert_equal merged, contents

    contents = nil
    output_file = File.join($DATA_DIR, 'test_out.css')
    assert_not_equal merged, contents
    assert @file_merger.save(output_file)

    assert_equal merged, IO.read(output_file)
  end
end
