require "test_helper"

class TestMergerBase < Test::Unit::TestCase

  def setup
    @file_merger = Juicer::Merger::Base.new
    Juicer::Test::FileSetup.new.create
  end

  def teardown
    file = path('test_out.css')
    File.delete(file) if File.exists?(file)
  end

  def test_constructor
    files = ['a.css', 'b.css'].collect { |file| path(file) }
    file_merger = Juicer::Merger::Base.new files
    assert_equal 2, file_merger.files.length
  end

  def test_append_duplicate_files
    @file_merger.append ['a.css', 'b.css'].collect { |file| path(file) }
    assert_equal 2, @file_merger.files.length,
           "b.css should not be included twice even when a.css imports it and it is manually added"
  end

  def test_append_duplicate
    @file_merger.append ['a.css', 'b.css'].collect { |file| path(file) }
    assert_equal 2, @file_merger.files.length

    @file_merger.append path('a.css')
    assert_equal 2, @file_merger.files.length

    @file_merger.append path('version.txt')
    assert_equal 3, @file_merger.files.length
  end

  def test_append_alias
    @file_merger << ['a.css', 'b.css'].collect { |file| path(file) }
    assert_equal 2, @file_merger.files.length
  end

  def test_save_to_stream
    a_css = path('a.css')
    a_css_contents = IO.read(a_css) + "\n"
    ios = StringIO.new
    @file_merger << a_css
    @file_merger.save ios
    assert_equal a_css_contents, ios.string
  end

  def test_save_to_file
    a_css = path('a.css')
    output_file = path('test_out.css')
    @file_merger << a_css
    @file_merger.save(output_file)

    assert_equal IO.read(a_css) + "\n", IO.read(output_file)
  end

  def test_save_merged_to_stream
    a_css = path('a.css')
    b_css = path('b.css')
    ios = StringIO.new

    @file_merger << a_css
    @file_merger << b_css
    @file_merger.save(ios)

    assert_equal "#{IO.read(a_css)}\n#{IO.read(b_css)}\n", ios.string
  end

  def test_save_merged_to_file
    a_css = path('a.css')
    b_css = path('b.css')
    a_contents = IO.read(a_css) + "\n"
    b_contents = IO.read(b_css) + "\n"
    output_file = path('test_out.css')

    @file_merger << a_css
    @file_merger << b_css
    @file_merger.save(output_file)

    assert_equal "#{IO.read(a_css)}\n#{IO.read(b_css)}\n", IO.read(output_file)
  end

  def test_resolve_dependencies
    Juicer::Merger::Base.publicize_methods do
      @file_merger.dependency_resolver = MockImportResolver.new

      @file_merger.resolve_dependencies('a.css')
      assert_equal 1, @file_merger.files.length

      @file_merger.resolve_dependencies('a.css')
      assert_equal 1, @file_merger.files.length
    end
  end

  def test_merge
    Juicer::Merger::Base.publicize_methods do
      a_content = <<EOF
@import 'b.css';

/* Dette er a.css */

EOF

      content = @file_merger.merge(path('a.css'))
      assert_equal a_content, content
    end
  end

  def test_attributes
    assert_not_nil @file_merger.files
  end
end

class MockImportResolver
  def resolve(file)
    [file]
  end
end
