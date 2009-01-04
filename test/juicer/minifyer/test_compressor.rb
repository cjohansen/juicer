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

  def test_get_option_string
    comp = Juicer::Minifyer::Compressor.new({ :a => '', :bee => '', :cee => nil, :dee => true })
    assert "-a --bee --dee".split.sort == comp.options.split.sort

    comp.bee = "hey"
    comp.cee = 3
    comp.dee = :val
    expected = "-a --bee hey --cee 3 --dee val"
    assert expected.split.sort == comp.options.split.sort, "#{expected} expected, got\n#{comp.options}"
  end

  def test_get_option_string_with_excludes
    comp = Juicer::Minifyer::Compressor.new({ :a => '', :bee => '', :cee => true, :dee => true })
    assert "--bee --cee --dee".split.sort == comp.options(:a).split.sort, "Got #{comp.options(:a)}"
    assert "--cee --dee".split.sort == comp.options(:bee, :a).split.sort, "Got #{comp.options(:bee, :a)}"
    assert "-a --dee".split.sort == comp.options([:cee, :bee]).split.sort, "Got #{comp.options([:cee, :bee])}"
  end

  def test_set_opts
    comp = Juicer::Minifyer::Compressor.new({ :a => '', :bee => '', :cee => true, :dee => true })
    comp.set_opts "-a 3 --dee test --bee=test2"
    assert "-a 3 --bee test2 --cee --dee test".split.sort == comp.options.split.sort, "Got #{comp.options}"
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
    assert @compressor.foo = 'bar'
    assert_equal 'bar', @compressor.get_opt(:foo)
    assert_equal 'bar', @compressor.foo
  end
end
