require File.expand_path(File.join(File.dirname(__FILE__), %w[.. test_helper])) unless defined?(Juicer)

class TestImageEmbed < Test::Unit::TestCase
  
  SUPPORTED_EXTENSIONS = %w{png gif jpg jpeg}
  PNG_FILE_CONTENT  = 'aGVsbG8gcG5n'      # 'hello png' base64 encoded
  GIF_FILE_CONTENT  = 'aGVsbG8gZ2lm'      # 'hello gif' base64 encoded
  JPG_FILE_CONTENT  = 'aGVsbG8ganBn'			# 'hello jpg' base64 encoded
  JPEG_FILE_CONTENT = 'aGVsbG8ganBlZw=='	# 'hello jpeg' base64 encoded
  BMP_FILE_CONTENT  = 'aGVsbG8gYm1w'			# 'hello bmp' base64 encoded
	EMBEDDABLE_URL = /\.\.\/images\/test_image\.(png|gif|jpg|jpeg)\?embed=true/
  
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
      assert_equal( path, @embedder.embed_data_uri( path ) )
    end

    should "not modify paths flagged as not embeddable" do
      path = '/somepath/somefile.png?embed=false'
      assert_equal( path, @embedder.embed_data_uri( path ) )
    end

    should "embed image when path flagged as embeddable" do
      path = path( 'images/1.png?embed=true' )
      assert_not_equal( path, @embedder.embed_data_uri( path ) )
    end

    should "support png, gif, jpg and jpeg images" do
      SUPPORTED_EXTENSIONS.each do |extension|
        path = path( "images/test_image.#{extension}?embed=true" )
        assert_not_equal( path, @embedder.embed_data_uri( path ) )
      end
    end
    
    should "not embed unsupported filetypes" do
      unsupported_extensions = %w{js txt swf ico bmp tif tiff applet jar}
      unsupported_extensions.each do |extension|
        path = "/somepath/somefile.#{extension}?embed=true"
        assert_equal( path, @embedder.embed_data_uri( path ) )
      end
    end

    should "set correct mimetype for supported extensions" do
      SUPPORTED_EXTENSIONS.each do |extension|
        path = path( "images/test_image.#{extension}?embed=true" )
        assert_match(/image\/#{extension}/, @embedder.embed_data_uri( path ) )
      end
    end
  end  # context 
  
  context "save method" do
    
    setup do 
      @css_file = path( 'css/image_embed_test.css' )
      assert( File.exists?( @css_file) )
    end
    
    should "embed images into css file" do
			variations = [
				{
					:css_file => path("css/image_embed_test_png_embed.css"),
					:image_file => path("images/test_image.png"),
					:mime_type => 'image/png'
				},{
					:css_file => path("css/image_embed_test_gif_embed.css"),
					:image_file => path("images/test_image.gif"),
					:mime_type => 'image/gif'
				},{
					:css_file => path("css/image_embed_test_jpg_embed.css"),
					:image_file => path("images/test_image.jpg"),
					:mime_type => 'image/jpg'
				},{
					:css_file => path("css/image_embed_test_jpeg_embed.css"),
					:image_file => path("images/test_image.jpeg"),
					:mime_type => 'image/jpeg'
				}
			]

	    image_embedder = Juicer::ImageEmbed.new
	
			variations.each do |variation|
				old_contents = File.read( variation[:css_file] )

				# let's make sure there is an embeddable url
				assert_match( EMBEDDABLE_URL, old_contents )

				# make sure there are no errors
		    assert_nothing_raised do
		      image_embedder.save variation[:css_file]
		    end

				css_contents = File.read(variation[:css_file])

				# make sure the original url does not exist anymore
				assert_no_match( EMBEDDABLE_URL, css_contents )

				# make sure the url has been converted into a data uri
				image_contents = File.read( variation[:image_file] )

				# create the data uri from the image contents
				data_uri = Datafy::make_data_uri( image_contents, variation[:mime_type] )

				# let's see if it exists in the file
				assert css_contents.include?( data_uri )
			end
	

    end
  end

end
