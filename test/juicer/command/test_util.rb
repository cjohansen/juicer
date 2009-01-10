require File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. test_helper])) unless defined?(Juicer)

class Dummy
  include Juicer::Command::Util
end

class TestCommandUtil < Test::Unit::TestCase

  def setup
    @impl = Dummy.new
    @file_setup = Juicer::Test::FileSetup.new($DATA_DIR)
    @file_setup.create!
  end

  def test_files_from_single_file
    files = @impl.files("test/data/a.css")
    assert files.is_a?(Array)
    assert_equal "test/data/a.css", files.sort.join
  end

  def test_files_from_single_glob_pattern
    files = @impl.files("test/data/*.css")
    assert files.is_a?(Array)
    assert_equal "test/data/a.csstest/data/b.css", files.sort.join
  end

  def test_files_from_mixed_arguments
    files = @impl.files("test/data/*.css", "test/data/a.js")
    assert files.is_a?(Array)
    assert_equal "test/data/a.csstest/data/a.jstest/data/b.css", files.sort.join
  end

  def test_files_from_array
    files = @impl.files(["test/data/*.css", "test/data/a.js"])
    assert files.is_a?(Array)
    assert_equal "test/data/a.csstest/data/a.jstest/data/b.css", files.sort.join
  end

  def test_relative_path_single_file
    assert_equal "test/data/a.css", @impl.relative("test/data/a.css")
  end

  def test_relative_path_many_files
    files = @impl.relative(Dir.glob("test/data/*.css"))
    assert files.is_a?(Array)
    assert_equal "test/data/a.csstest/data/b.css", files.sort.join
  end

  def test_relative_path_many_files_explicit_reference
    files = @impl.relative(Dir.glob("test/data/*.css"), "lib")
    assert files.is_a?(Array)
    assert_equal "../test/data/a.css../test/data/b.css", files.sort.join
  end
end
