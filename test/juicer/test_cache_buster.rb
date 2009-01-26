require File.expand_path(File.join(File.dirname(__FILE__), %w[.. test_helper])) unless defined?(Juicer)

class TestCacheBuster < Test::Unit::TestCase
  def setup
    Juicer::Test::FileSetup.new.create
  end

  def test_default_type_and_param_name
    file = path("a.js")
    mtime = File.new(file).mtime.to_i
    assert_equal "#{file}?jcb=#{mtime}", Juicer::CacheBuster.path(file)
  end

  def test_soft_path_default_param_name
    file = path("a.js")
    mtime = File.new(file).mtime.to_i
    assert_equal "#{file}?jcb=#{mtime}", Juicer::CacheBuster.path(file, :soft)
  end

  def test_soft_path
    file = path("a.js")
    mtime = File.new(file).mtime.to_i
    assert_equal "#{file}?mtime=#{mtime}", Juicer::CacheBuster.path(file, :soft, "mtime")
    assert_equal "#{file}?mtime=#{mtime}", Juicer::CacheBuster.path(file, :soft, :mtime)
  end

  def test_soft_path_with_empty_param_name
    file = path("a.js")
    mtime = File.new(file).mtime.to_i
    assert_equal "#{file}?#{mtime}", Juicer::CacheBuster.path(file, :soft, nil)
    assert_equal "#{file}?#{mtime}", Juicer::CacheBuster.path(file, :soft, "")
  end

  def test_hard_path_default_param_name
    file = path("a.js")
    mtime = File.new(file).mtime.to_i
    assert_equal "#{File.dirname(file)}/a-#{mtime}.js", Juicer::CacheBuster.path(file, :hard)
  end

  def test_hard_path_with_empty_param_name
    file = path("a.js")
    mtime = File.new(file).mtime.to_i
    assert_equal "#{File.dirname(file)}/a-#{mtime}.js", Juicer::CacheBuster.path(file, :hard, "")
    assert_equal "#{File.dirname(file)}/a-#{mtime}.js", Juicer::CacheBuster.path(file, :hard, nil)
  end

  def test_hard_path
    file = path("a.js")
    mtime = File.new(file).mtime.to_i
    assert_equal "#{File.dirname(file)}/a-cb#{mtime}.js", Juicer::CacheBuster.path(file, :hard, "cb")
  end

  def test_cached_path_should_be_updated_soft
    file = path("a.js")
    mtime = File.new(file).mtime.to_i
    assert_equal "#{File.dirname(file)}/a.js?cb=#{mtime}", Juicer::CacheBuster.path("#{file}?cb=1234", :soft, "cb")
  end
end
