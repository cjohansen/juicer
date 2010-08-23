require "test_helper"

class TestStylesheetMerger < Test::Unit::TestCase
  def setup
    @file_merger = Juicer::Merger::StylesheetMerger.new
    Juicer::Test::FileSetup.new.create
    @cwd = Dir.pwd
    Dir.chdir path("")
  end

  def teardown
    file = path('test_out.css')
    File.delete(file) if File.exists?(file)
    Dir.chdir(@cwd)
  end

  context "stylesheet merger" do
    should "keep reference to css dependency resolver" do
      Juicer::Merger::StylesheetMerger.publicize_methods do
        resolver = @file_merger.dependency_resolver

        assert_equal Juicer::CssDependencyResolver, resolver.class
      end
    end

    should "merge single file" do
      Juicer::Merger::StylesheetMerger.publicize_methods do
        a_content = "\n\n/* Dette er a.css */\n"
        content = @file_merger.merge(path('a.css'))

        assert_equal a_content + "\n", content
      end
    end

    should "recognize all files" do
      file_merger = Juicer::Merger::StylesheetMerger.new(path('a.css'))

      assert_equal 2, file_merger.files.length
    end

    should "not append existing file" do
      @file_merger << path('a.css')
      assert_equal 2, @file_merger.files.length
    end
  end

  context "saving files" do
    should "merge files and strip @includes" do
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

    should "strip @includes for quoted urls" do
      css = path('b2.css')

      merged = <<EOF
h2 {
    font-size: 10px;
}



html {
    background: red;
}

EOF

      @file_merger << css
      ios = StringIO.new
      @file_merger.save(ios)
      assert_equal merged, ios.string
    end
  end

  context "resolving paths" do
    should "re-reference relative paths" do
      @file_merger << path("path_test.css")
      ios = StringIO.new
      @file_merger.save(ios)
      files = ios.string.scan(/url\(([^\)]*)\)/).collect { |f| f.first }.uniq.sort

      assert_equal "a1.css::css/2.gif::images/1.png", files.join("::")
    end

    should "not touch absolute urls" do
      merger = Juicer::Merger::StylesheetMerger.new
      url = "/some/url"

      Juicer::Merger::StylesheetMerger.publicize_methods do
        assert_equal url, merger.resolve_path(url, nil)
      end
    end

    should "raise when mapping absolute to relative path without document root" do
      merger = Juicer::Merger::StylesheetMerger.new [], :relative_urls => true

      Juicer::Merger::StylesheetMerger.publicize_methods do
        assert_raise ArgumentError do
          merger.resolve_path("/some/url", nil)
        end
      end
    end

    should "make absolute urls relative" do
      merger = Juicer::Merger::StylesheetMerger.new([],
                                                    :relative_urls => true,
                                                    :document_root => "/home/usr")

      Juicer::Merger::StylesheetMerger.publicize_methods do
        merger.instance_eval { @root = Pathname.new "/home/usr/design" }

        assert_equal "../some/url", merger.resolve_path("/some/url", nil)
      end
    end

    should "should leave full urls" do
      merger = Juicer::Merger::StylesheetMerger.new []
      url = "http://test.com"

      Juicer::Merger::StylesheetMerger.publicize_methods do
        merger.instance_eval { @root = Pathname.new "/home/usr/design" }

        assert_equal url, merger.resolve_path(url, nil)
      end
    end

    should "error when missing document root for absolute urls" do
      merger = Juicer::Merger::StylesheetMerger.new [], :absolute_urls => true

      Juicer::Merger::StylesheetMerger.publicize_methods do
        assert_raise ArgumentError do
          merger.resolve_path("../some/url", nil)
        end
      end
    end

    should "make relative urls absolute" do
      merger = Juicer::Merger::StylesheetMerger.new([],
                                                    :absolute_urls => true,
                                                    :document_root => "/home/usr")

      Juicer::Merger::StylesheetMerger.publicize_methods do
        merger.instance_eval { @root = Pathname.new "/home/usr/design" }
        assert_equal "/design/images/1.png", merger.resolve_path("../images/1.png", "/home/usr/design/css")
      end
    end

    should "redefine relative urls" do
      merger = Juicer::Merger::StylesheetMerger.new [], :relative_urls => true

      Juicer::Merger::StylesheetMerger.publicize_methods do
        merger.instance_eval { @root = Pathname.new "/home/usr/design2/css" }
        assert_equal "../../design/images/1.png", merger.resolve_path("../images/1.png", "/home/usr/design/css")
      end
    end

    should "redefine absolute urls" do
      merger = Juicer::Merger::StylesheetMerger.new([],
                                                    :relative_urls => true,
                                                    :document_root => "/home/usr")

      Juicer::Merger::StylesheetMerger.publicize_methods do
        merger.instance_eval { @root = Pathname.new "/home/usr/design2/css" }
        result = merger.resolve_path("/images/1.png", "/home/usr/design/css")

        assert_equal "../../images/1.png", result
      end
    end

    should "cycle asset hosts" do
      hosts = ["http://assets1", "http://assets2", "http://assets3"]
      merger = Juicer::Merger::StylesheetMerger.new([], :hosts => hosts)

      Juicer::Merger::StylesheetMerger.publicize_methods do
        merger.instance_eval do
          @root = Pathname.new "/home/usr/design2/css"
        end

        assert_equal "http://assets1/images/1.png", merger.resolve_path("/images/1.png", nil)
        assert_equal "http://assets2/images/1.png", merger.resolve_path("/images/1.png", nil)
        assert_equal "http://assets3/images/1.png", merger.resolve_path("/images/1.png", nil)
        assert_equal "http://assets1/images/1.png", merger.resolve_path("/images/1.png", nil)
      end
    end

    should "handle relative document roots" do
      merger = Juicer::Merger::StylesheetMerger.new([],
                                                    :document_root => "test/data",
                                                    :relative_urls => true)
      merger << File.expand_path("css/test2.css")

      Juicer::Merger::StylesheetMerger.publicize_methods do
        merger.instance_eval do
          @root = Pathname.new File.expand_path("test/data/css")
        end

        assert_equal "../images/1.png", merger.resolve_path("/images/1.png", nil)
      end
    end
    
    should "leave data URLs untouched" do
      merger = Juicer::Merger::StylesheetMerger.new([],
                                                    :document_root => "test/data",
                                                    :hosts => ["http://assets1/"])
      merger << File.expand_path("path_test2.css")

      Juicer::Merger::StylesheetMerger.publicize_methods do
        merger.instance_eval do
          @root = Pathname.new(File.expand_path("test/data/css"))
        end

        expected = "data:image/png;base64,ERJW"
        assert_equal expected, merger.resolve_path("data:image/png;base64,ERJW", "test/data/css")
      end
    end

    should "cycle hosts for relative urls" do
      merger = Juicer::Merger::StylesheetMerger.new([],
                                                    :document_root => "test/data",
                                                    :hosts => ["http://assets1/"])
      merger << File.expand_path("path_test2.css")

      Juicer::Merger::StylesheetMerger.publicize_methods do
        merger.instance_eval do
          @root = Pathname.new(File.expand_path("test/data/css"))
        end

        expected = "http://assets1/images/1.png"
        assert_equal expected, merger.resolve_path("../images/1.png", "test/data/css")
      end
    end

    should "use same host for same url when cycling asset hosts" do
      @file_merger = Juicer::Merger::StylesheetMerger.new nil, :hosts => ["http://assets1", "http://assets2", "http://assets3"]
      @file_merger << path("path_test2.css")
      ios = StringIO.new
      @file_merger.save(ios)
      files = ios.string.scan(/url\(([^\)]*)\)/).collect { |f| f.first }

      assert_equal "1/images/1.png::2/css/2.gif::3/a1.css::2/css/2.gif::1/a2.css".gsub(/(\d\/)/, 'http://assets\1'), files.join("::")
    end
  end
end
