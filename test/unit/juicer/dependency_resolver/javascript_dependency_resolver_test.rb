require "test_helper"

class TestJavaScriptDependencyResolver < Test::Unit::TestCase

  def setup
    @resolver = Juicer::JavaScriptDependencyResolver.new
    Juicer::Test::FileSetup.new.create
  end

  def test_init
    assert_equal [], @resolver.files
  end

  def test_resolve
    b_file = path('b.js')
    a_file = path('a.js')

    files = @resolver.resolve(a_file) do |file|
      assert b_file == file || a_file == file, file
      b_file != file
    end

    assert_equal [a_file], files

    files = @resolver.resolve(a_file) do |file|
      assert b_file == file || a_file == file
      true
    end

    assert_equal [a_file, b_file], files.sort

    files = @resolver.resolve(b_file) do |file|
      assert b_file == file || a_file == file
      true
    end

    assert_equal [a_file, b_file], files.sort
  end
end
