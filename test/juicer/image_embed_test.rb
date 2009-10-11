require File.expand_path(File.join(File.dirname(__FILE__), %w[.. test_helper])) unless defined?(Juicer)

class TestImageEmbed < Test::Unit::TestCase
  
  SUPPORTED_EXTENSIONS = %w{png gif jpg jpeg}
  
  def setup
    Juicer::Test::FileSetup.new.create
    @embedder = Juicer::ImageEmbed.new
  end

  def teardown
    Juicer::Test::FileSetup.new.delete
    Juicer::Test::FileSetup.new.create
  end

  context "embed method" do
    should "not modify regular paths" do
      path = path( 'images/test_image.png' )
      assert_equal( path, @embedder.embed( path ) )
    end

    should "not modify paths flagged as not embeddable" do
      path = '/somepath/somefile.png?embed=false'
      assert_equal( path, @embedder.embed( path ) )
    end

    should "embed image when path flagged as embeddable" do
      path = path( 'images/1.png?embed=true' )
      assert_not_equal( path, @embedder.embed( path ) )
    end

    should "support png, gif, jpg and jpeg images" do
      SUPPORTED_EXTENSIONS.each do |extension|
        path = path( "images/test_image.#{extension}?embed=true" )
        assert_not_equal( path, @embedder.embed( path ) )
      end
    end
    
    should "not embed unsupported filetypes" do
      unsupported_extensions = %w{js txt swf ico bmp tif tiff applet jar}
      unsupported_extensions.each do |extension|
        path = "/somepath/somefile.#{extension}?embed=true"
        assert_equal( path, @embedder.embed( path ) )
      end
    end

    should "set correct mimetype for supported extensions" do
      SUPPORTED_EXTENSIONS.each do |extension|
        path = path( "images/test_image.#{extension}?embed=true" )
        assert_match(/image\/#{extension}/, @embedder.embed( path ) )
      end
    end

  end  
end
