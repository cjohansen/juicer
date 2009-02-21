require File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. test_helper])) unless defined?(Juicer)

class TestStylesheetMerger < Test::Unit::TestCase

  def setup
    @file_merger = Juicer::Merger::StylesheetMerger.new
    Juicer::Test::FileSetup.new.create
    Dir.chdir path("")
  end

  def teardown
    file = path('test_out.css')
    File.delete(file) if File.exists?(file)
  end

  def test_init
    Juicer::Merger::StylesheetMerger.publicize_methods do
      assert_equal Juicer::Merger::CssDependencyResolver, @file_merger.dependency_resolver.class
    end
  end

  def test_merge
    Juicer::Merger::StylesheetMerger.publicize_methods do
      a_content = "\n\n/* Dette er a.css */\n"
      content = @file_merger.merge(path('a.css'))
      assert_equal a_content + "\n", content
    end
  end

  def test_constructor
    file_merger = Juicer::Merger::StylesheetMerger.new(path('a.css'))
    assert_equal 2, file_merger.files.length
  end

  def test_append
    @file_merger << path('a.css')
    assert_equal 2, @file_merger.files.length
  end

  def test_save
    a_css = path('a.css')
    b_css = path('b.css')
    merged = <<EOF
/* Dette er b.css */



/* Dette er a.css */

EOF

    @file_merger << a_css
    ios = StringIO.new
    @file_merger.save(ios)
    assert_equal merged, ios.string

    output_file = path('test_out.css')
    @file_merger.save(output_file)

    assert_equal merged, IO.read(output_file)
  end

  def test_included_files_should_have_referenced_relative_urls_rereferenced
    @file_merger << path("path_test.css")
    ios = StringIO.new
    @file_merger.save(ios)
    files = ios.string.scan(/url\(([^\)]*)\)/).collect { |f| f.first }.uniq.sort

    assert_equal "a1.css::css/2.gif::images/1.png", files.join("::")
  end

  def test_resolve_path_should_leave_absolute_urls
    merger = Juicer::Merger::StylesheetMerger.new
    url = "/some/url"

    Juicer::Merger::StylesheetMerger.publicize_methods do
      assert_equal url, merger.resolve_path(url, nil)
    end
  end

  def test_resolve_path_error_when_relative_missing_web_root
    merger = Juicer::Merger::StylesheetMerger.new [], :relative_urls => true

    Juicer::Merger::StylesheetMerger.publicize_methods do
      assert_raise ArgumentError do
        merger.resolve_path("/some/url", nil)
      end
    end
  end

  def test_resolve_path_should_make_absolute_urls_relative
    merger = Juicer::Merger::StylesheetMerger.new [], :relative_urls => true, :web_root => "/home/usr"

    Juicer::Merger::StylesheetMerger.publicize_methods do
      merger.instance_eval { @root = Pathname.new "/home/usr/design" }
      assert_equal "../some/url", merger.resolve_path("/some/url", nil)
    end
  end

  def test_resolve_path_should_leave_full_urls
    merger = Juicer::Merger::StylesheetMerger.new []
    url = "http://test.com"

    Juicer::Merger::StylesheetMerger.publicize_methods do
      merger.instance_eval { @root = Pathname.new "/home/usr/design" }
      assert_equal url, merger.resolve_path(url, nil)
    end
  end

  def test_resolve_path_error_when_missing_absolute_web_root
    merger = Juicer::Merger::StylesheetMerger.new [], :absolute_urls => true

    Juicer::Merger::StylesheetMerger.publicize_methods do
      assert_raise ArgumentError do
        merger.resolve_path("../some/url", nil)
      end
    end
  end

  def test_resolve_path_should_make_relative_urls_absolute
    merger = Juicer::Merger::StylesheetMerger.new [], :absolute_urls => true, :web_root => "/home/usr"

    Juicer::Merger::StylesheetMerger.publicize_methods do
      merger.instance_eval { @root = Pathname.new "/home/usr/design" }
      assert_equal "/design/images/1.png", merger.resolve_path("../images/1.png", "/home/usr/design/css")
    end
  end

  def test_resolve_path_should_redefine_relative_urls
    merger = Juicer::Merger::StylesheetMerger.new [], :relative_urls => true

    Juicer::Merger::StylesheetMerger.publicize_methods do
      merger.instance_eval { @root = Pathname.new "/home/usr/design2/css" }
      assert_equal "../../design/images/1.png", merger.resolve_path("../images/1.png", "/home/usr/design/css")
    end
  end

  def test_resolve_path_should_redefine_absolute_urls
    merger = Juicer::Merger::StylesheetMerger.new [], :relative_urls => true, :web_root => "/home/usr"

    Juicer::Merger::StylesheetMerger.publicize_methods do
      merger.instance_eval { @root = Pathname.new "/home/usr/design2/css" }
      assert_equal "../../images/1.png", merger.resolve_path("/images/1.png", "/home/usr/design/css")
    end
  end

  def test_resolve_path_with_hosts_should_cycle_asset_hosts
    merger = Juicer::Merger::StylesheetMerger.new [], :hosts => ["http://assets1", "http://assets2", "http://assets3"]

    Juicer::Merger::StylesheetMerger.publicize_methods do
      merger.instance_eval { @root = Pathname.new "/home/usr/design2/css" }
      assert_equal "http://assets1/images/1.png", merger.resolve_path("/images/1.png", nil)
      assert_equal "http://assets2/images/1.png", merger.resolve_path("/images/1.png", nil)
      assert_equal "http://assets3/images/1.png", merger.resolve_path("/images/1.png", nil)
      assert_equal "http://assets1/images/1.png", merger.resolve_path("/images/1.png", nil)
    end
  end

  def test_resolve_paths_should_handle_relative_web_roots
    merger = Juicer::Merger::StylesheetMerger.new [], :web_root => "test/data", :relative_urls => true
    merger << File.expand_path("css/test2.css")

    Juicer::Merger::StylesheetMerger.publicize_methods do
      merger.instance_eval { @root = Pathname.new File.expand_path("test/data/css") }
      assert_equal "../images/1.png", merger.resolve_path("/images/1.png", nil)
    end
  end

  def test_cycle_asset_hosts_should_use_same_host_for_same_url
    @file_merger = Juicer::Merger::StylesheetMerger.new nil, :hosts => ["http://assets1", "http://assets2", "http://assets3"]
    @file_merger << path("path_test2.css")
    ios = StringIO.new
    @file_merger.save(ios)
    files = ios.string.scan(/url\(([^\)]*)\)/).collect { |f| f.first }

    assert_equal "1/images/1.png::2/css/2.gif::3/a1.css::2/css/2.gif::1/a2.css".gsub(/(\d\/)/, 'http://assets\1'), files.join("::")
  end
end
