require File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. test_helper])) unless defined?(Juicer)

class TestFileMerger < Test::Unit::TestCase

  def setup
    @file_merger = Juicer::Merger::FileMerger.new
    @file_setup = Juicer::Test::FileSetup.new($DATA_DIR)
    @file_setup.create!
  end

  def teardown
    file = File.join($DATA_DIR, 'test_out.css')
    File.delete(file) if File.exists?(file)
  end

  def test_append
    @file_merger << ['a.css', 'b.css'].collect { |file| File.join($DATA_DIR, file) }
    assert_equal 2, @file_merger.files.length

    @file_merger << File.join($DATA_DIR, 'a.css')
    assert_equal 2, @file_merger.files.length

    @file_merger << File.join($DATA_DIR, 'version.txt')
    assert_equal 3, @file_merger.files.length
  end

  def test_save
    a_css = File.join($DATA_DIR, 'a.css')
    a_css_contents = IO.read(a_css) + "\n"
    @file_merger << a_css
    assert_equal a_css_contents, @file_merger.save

    contents = nil
    output_file = File.join($DATA_DIR, 'test_out.css')
    assert_not_equal contents, a_css_contents
    assert @file_merger.save(output_file)
    assert_equal IO.read(output_file), a_css_contents

    b_css = File.join($DATA_DIR, 'b.css')
    b_css_contents = IO.read(b_css) + "\n"
    @file_merger << b_css

    contents = @file_merger.save
    assert_equal "#{a_css_contents}#{b_css_contents}", contents

    output_file = File.join($DATA_DIR, 'test_out.css')
    assert @file_merger.save(output_file)
    assert_equal "#{a_css_contents}#{b_css_contents}", IO.read(output_file)
    assert_equal contents, IO.read(output_file)
  end

  def test_resolve_imports
    Juicer::Merger::FileMerger.publicize_methods do
      @file_merger.dependency_resolver = MockImportResolver.new

      @file_merger.resolve_imports('a.css')
      assert_equal 1, @file_merger.files.length

      @file_merger.resolve_imports('a.css')
      assert_equal 1, @file_merger.files.length
    end
  end

  def test_merge
    Juicer::Merger::FileMerger.publicize_methods do
      a_content = <<EOF
@import 'b.css';

/* Dette er a.css */

EOF

      content = @file_merger.merge(File.join($DATA_DIR, 'a.css'))
      assert_equal a_content, content
    end
  end

  def test_attributes
    assert_not_nil @file_merger.files
  end
end

class MockImportResolver
  def resolve(file)
    yield file
  end
end
