require File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. test_helper])) unless defined?(Juicer)

class TestStylesheetMerger < Test::Unit::TestCase

  def setup
    @file_merger = Juicer::Merger::StylesheetMerger.new
    @file_setup = Juicer::Test::FileSetup.new($DATA_DIR)
    @file_setup.create!
  end

  def teardown
    file = path('test_out.css')
    File.delete(file) if File.exists?(file)
  end

  def test_init
    Juicer::Merger::StylesheetMerger.publicize_methods do
      assert_equal Juicer::Merger::CssDependencyResolver, @file_merger.dependency_resolver.class
    end
  end

  def test_merge
    Juicer::Merger::StylesheetMerger.publicize_methods do
      a_content = "\n\n/* Dette er a.css */\n"
      content = @file_merger.merge(path('a.css'))
      assert_equal a_content + "\n", content
    end
  end

  def test_constructor
    file_merger = Juicer::Merger::StylesheetMerger.new(path('a.css'))
    assert_equal 2, file_merger.files.length
  end

  def test_append
    @file_merger << path('a.css')
    assert_equal 2, @file_merger.files.length
  end

  def test_save
    a_css = path('a.css')
    b_css = path('b.css')
    merged = <<EOF
/* Dette er b.css */



/* Dette er a.css */

EOF

    @file_merger << a_css
    ios = StringIO.new
    @file_merger.save(ios)
    assert_equal merged, ios.string

    output_file = path('test_out.css')
    @file_merger.save(output_file)

    assert_equal merged, IO.read(output_file)
  end
end
