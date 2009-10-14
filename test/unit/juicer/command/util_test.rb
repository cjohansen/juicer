require "test_helper"

class Dummy
  include Juicer::Command::Util
end

class TestCommandUtil < Test::Unit::TestCase

  def setup
    @impl = Dummy.new
    Juicer::Test::FileSetup.new.create
    Dir.glob("test/data/*.min.css").each { |file| File.delete(file) }
  end

  def test_files_from_single_file
    files = @impl.files("test/data/a.css")
    assert files.is_a?(Array)
    assert_equal "test/data/a.css", files.sort.join
  end

  def test_files_from_single_glob_pattern
    files = @impl.files("test/data/*.css")
    assert files.is_a?(Array)
    assert_equal %w{a.css a1.css b.css b1.css c1.css d1.css path_test.css path_test2.css}.collect { |f| "test/data/#{f}" }.join, files.sort.join
  end

  def test_files_from_mixed_arguments
    files = @impl.files("test/data/*.css", "test/data/a.js")
    assert files.is_a?(Array)
    assert_equal %w{a.css a.js a1.css b.css b1.css c1.css d1.css path_test.css path_test2.css}.collect { |f| "test/data/#{f}" }.join, files.sort.join
  end

  def test_files_from_array
    files = @impl.files(["test/data/*.css", "test/data/a.js"])
    assert files.is_a?(Array)
    assert_equal %w{a.css a.js a1.css b.css b1.css c1.css d1.css path_test.css path_test2.css}.collect { |f| "test/data/#{f}" }.join, files.sort.join
  end

  def test_relative_path_single_file
    assert_equal "test/data/a.css", @impl.relative("test/data/a.css")
  end

  def test_relative_path_many_files
    files = @impl.relative(Dir.glob("test/data/*.css"))
    assert files.is_a?(Array)
    assert_equal %w{a.css a1.css b.css b1.css c1.css d1.css path_test.css path_test2.css}.collect { |f| "test/data/#{f}" }.join, files.sort.join
  end

  def test_relative_path_many_files_explicit_reference
    files = @impl.relative(Dir.glob("test/data/*.css"), "lib")
    assert files.is_a?(Array)
    assert_equal %w{a.css a1.css b.css b1.css c1.css d1.css path_test.css path_test2.css}.collect { |f| "../test/data/#{f}" }.join, files.sort.join
  end
end
