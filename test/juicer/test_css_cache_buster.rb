require File.expand_path(File.join(File.dirname(__FILE__), %w[.. test_helper])) unless defined?(Juicer)

class TestCssCacheBuster < Test::Unit::TestCase
  def setup
    Juicer::Test::FileSetup.new.create
    @buster = Juicer::CssCacheBuster.new
  end

  def teardown
    Juicer::Test::FileSetup.new.delete
  end

  def test_resolve_full_url
    assert_equal "http://localhost/images/1.png", @buster.resolve("http://localhost/images/1.png", "")
  end

  def test_resolve_relative_url
    file = path("images/1.png")
    assert_equal(file, @buster.resolve("../images/1.png", path("css/test.css")))
  end

  def test_resolve_absolute_url_without_web_root_should_fail
    file = path("images/1.png")
    assert_raise FileNotFoundError do
      @buster.resolve("/images/1.png", path("css/test.css"))
    end
  end

  def test_resolve_absolute_url_with_web_root
    buster = Juicer::CssCacheBuster.new :web_root => path("")
    file = path("images/1.png")
    assert_equal(file, buster.resolve("/images/1.png", path("css/test.css")))
  end

  def test_find_urls
    urls = @buster.urls(path("css/test.css"))
    assert_equal 3, urls.length
    assert_equal "../a1.css../images/1.png2.gif", urls.sort.join.gsub(path("/"), "")
  end

  def test_image_references_should_be_updated
    file = path("css/test.css")
    buster = Juicer::CssCacheBuster.new
    buster.save file

    File.read(file).scan(/url\(([^\)]*)\)/m).each do |path|
      assert_match(/[^\?]*\?jcb=\d+/, path.first)
    end
  end

  def test_absolute_path_without_web_root_should_fail
    file = path("css/test2.css")
    buster = Juicer::CssCacheBuster.new

    assert_raise FileNotFoundError do
      buster.save file
    end
  end

  def test_absolute_path_should_be_resolved_when_web_root_known
    file = path("css/test.css")
    buster = Juicer::CssCacheBuster.new :web_root => path("")

    assert_nothing_raised do
      buster.save file
    end

    File.read(file).scan(/url\(([^\)]*)\)/m).each do |path|
      assert_match(/[^\?]*\?jcb=\d+/, path.first)
    end
  end
end
