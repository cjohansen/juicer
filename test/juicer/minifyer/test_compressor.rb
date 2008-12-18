require File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. test_helper])) unless defined?(Juicer)

class TestCompressor < Test::Unit::TestCase

  def setup
    @compressor = Juicer::Minifyer::Compressor.new({ :test_opt => '', :foo => '' })
    @file_setup = Juicer::Test::FileSetup.new($DATA_DIR)
    @file_setup.create!
  end

  def test_get_opt
    assert_equal '', @compressor.get_opt(:test_opt)
    @compressor.set_opt(:test_opt, 'some_str')
    assert_equal 'some_str', @compressor.get_opt(:test_opt)
  end

  def test_set_opt
    assert @compressor.set_opt(:test_opt, 'some_str')
    assert_equal 'some_str', @compressor.get_opt(:test_opt)
  end

  def test_default_options
    Juicer::Minifyer::Compressor.publicize_methods do
      obj = {}
      assert_equal obj, @compressor.default_options
    end
  end

  def test_method_missing
    assert_not_equal 'bar', @compressor.get_opt(:foo)
    assert_not_equal 'bar', @compressor.foo
    assert (@compressor.foo = 'bar')
    assert_equal 'bar', @compressor.get_opt(:foo)
    assert_equal 'bar', @compressor.foo
  end
end
