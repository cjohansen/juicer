require "test_helper"

class TestCssDependencyResolver < Test::Unit::TestCase
  def setup
    @resolver = Juicer::CssDependencyResolver.new
    Juicer::Test::FileSetup.new.create
  end

  def test_init
    assert_equal [], @resolver.files
  end

  def test_resolve
    b_file = path('b.css')
    a_file = path('a.css')

    files = @resolver.resolve(path('a.css')) do |file|
      assert b_file == file || a_file == file
      b_file != file
    end

    assert_equal [a_file], files

    files = @resolver.resolve(path('a.css')) do |file|
      assert b_file == file || a_file == file
      true
    end

    assert_equal [a_file, b_file], files.sort
  end

  def test_load_order
    files = @resolver.resolve(path("a1.css")).collect { |file| file.split("/").pop }
    assert_equal "d1.cssb1.cssc1.cssa1.css", files.join
  end
end
