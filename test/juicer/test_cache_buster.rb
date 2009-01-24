require File.expand_path(File.join(File.dirname(__FILE__), %w[.. test_helper])) unless defined?(Juicer)

class TestCacheBuster < Test::Unit::TestCase
  def test_
    Juicer::CacheBuster.url(file, :soft)
    Juicer::CacheBuster.url(file, :hard)
  end
end
