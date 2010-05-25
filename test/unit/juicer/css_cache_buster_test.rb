require "test_helper"

class TestCssCacheBuster < Test::Unit::TestCase
  def setup
    Juicer::Test::FileSetup.new.create
    @buster = Juicer::CssCacheBuster.new
  end

  def teardown
    Juicer::Test::FileSetup.new.delete
    Juicer::Test::FileSetup.new.create
  end

  context "finding urls" do
    should "find all urls" do
      urls = @buster.urls(path("css/test.css"))
      assert_equal 4, urls.length
      assert_equal "../a1.css../images/1.png2.gif2.gif", urls.collect { |a| a.path }.sort.join.gsub(path("/"), "")
    end
  end

  context "image references" do
    should "update image urls" do
      file = path("css/test.css")
      buster = Juicer::CssCacheBuster.new
      buster.save file

      File.read(file).scan(/url\(([^\)]*)\)/m).each do |path|
        assert_match(/[^\?]*\?jcb=\d+/, path.first)
      end
    end

    should "not add multiple cache busters" do
      file = path("css/test.css")
      buster = Juicer::CssCacheBuster.new
      buster.save file

      assert_no_match /2\.gif\?jcb=\d+\?jcb=/, File.read(file)
    end

    should "not add multiple cache busters when asset host cycling is used" do
      file = path("css/test3.css")
      buster = Juicer::CssCacheBuster.new( { :hosts => [ 'http://assets1', 'http://assets2', 'http://assets3' ], :document_root => './test/data' } )
      buster.save file

      assert_no_match /2\.gif\?jcb=\d+\?jcb=/, File.read(file)
    end

  end

  context "absolute paths" do
    # should "fail without document root" do
    #   file = path("css/test2.css")
    #   buster = Juicer::CssCacheBuster.new

    #   assert_raise FileNotFoundError do
    #     buster.save file
    #   end
    # end

    should "resolve with document root" do
      file = path("css/test.css")
      buster = Juicer::CssCacheBuster.new :document_root => path("")

      assert_nothing_raised do
        buster.save file
      end

      File.read(file).scan(/url\(([^\)]*)\)/m).each do |path|
        assert_match(/[^\?]*\?jcb=\d+/, path.first)
      end
    end
  end

  context "cache busters" do
    should "add mtime to urls" do
      File.open(path("a2.css"), "w") { |f| f.puts "" }
      file = path("path_test2.css")
      output = path("path_test3.css")
      buster = Juicer::CssCacheBuster.new :document_root => path("")
      buster.save file, output

      buster.urls(output).each { |url| assert url !~ /(jcb=\d+).*(jcb=\d+)/, url }
    end
  end

  context "rails cache busters" do
    should "should append mtime to urls" do
      File.open(path("a2.css"), "w") { |f| f.puts "" }
      file = path("path_test2.css")
      output = path("path_test3.css")
      buster = Juicer::CssCacheBuster.new :document_root => path(""), :type => :rails
      buster.save file, output

      buster.urls(output).each { |asset| assert_match /\?\d+$/, asset.path }
    end
  end
  
  context "hard cache busters" do
    should "should alter file name" do
      File.open(path("a2.css"), "w") { |f| f.puts "" }
      file = path("path_test2.css")
      output = path("path_test3.css")
      buster = Juicer::CssCacheBuster.new :document_root => path(""), :type => :hard
      buster.save file, output

      buster.urls(output).each { |asset| assert_match /-jcb\d+\.[a-z]{3}$/, asset.path }
    end
  end

  context "non-existent urls" do
    should "not raise" do
      File.open(path("a2.css"), "w") { |f| f.puts "a { background: url(i/dont/exist.fck); }" }
      file = path("a2.css")
      buster = Juicer::CssCacheBuster.new :document_root => path("")

      assert_nothing_raised do
        buster.save file        
      end
    end
  end
end
