require File.expand_path(File.join(File.dirname(__FILE__), %w[.. test_helper])) unless defined?(Juicer)
require 'fakefs'

class TestImageEmbed < Test::Unit::TestCase
	include FakeFS
  
	context "ImageEmbed instance using data_uri," do
		
		setup do 
			FileSystem.clear
			FileUtils.mkdir_p("/stylesheets")
			FileUtils.mkdir_p("/images")

			@supported_assets = [
				{ :path => '/images/test.png', :content => 'hello png!' },
				{ :path => '/images/test.gif', :content => 'hello gif!'	},
				{	:path => '/images/test.jpg', :content => 'hello jpg!'	},
				{ :path => '/images/test.jpeg', :content => 'hello jpeg!' },
			]	
			create_files( @supported_assets )
			
			@unsupported_assets = [
				{ :path => '/images/test.bmp', :content => 'hello bmp!' },
				{ :path => '/images/test.js', :content => 'hello js!'	},
				{ :path => '/images/test.txt', :content => 'hello txt!'	},
				{ :path => '/images/test.swf', :content => 'hello swf!'	},
				{ :path => '/images/test.swf', :content => 'hello swf!'	},
				{ :path => '/images/test.ico', :content => 'hello ico!'	},
				{ :path => '/images/test.tif', :content => 'hello tif!'	},
				{ :path => '/images/test.tiff', :content => 'hello tiff!'	},
				{ :path => '/images/test.applet', :content => 'hello applet!'	},
				{ :path => '/images/test.jar', :content => 'hello jar!'	}
			]	
			create_files( @unsupported_assets )
			@embedder = Juicer::ImageEmbed.new( :type => :data_uri, :web_root => '' )
		end

		context "save method" do
	    setup do 
				@stylesheets = [
					{ 
						:path => '/stylesheets/test_embed_true.css', 
						:content => "body: { background: url(#{@supported_assets.first[:path]}?embed=true); }"
					}
				]
				create_files( @stylesheets )
	    end


	    should "embed images into css file" do
   			@stylesheets.each do |stylesheet|
   				old_contents = File.read( stylesheet[:path] )
   
   				# make sure there are no errors
   		    assert_nothing_raised do
   		      @embedder.save stylesheet[:path]
   		    end
   
   				css_contents = File.read( stylesheet[:path] )
   				   
   				# make sure the original url does not exist anymore
   				assert_no_match( Regexp.new( @supported_assets.first[:path] ), css_contents )

   				# make sure the url has been converted into a data uri
   				image_contents = File.read( @supported_assets.first[:path] )

   				# # create the data uri from the image contents
   				data_uri = Datafy::make_data_uri( image_contents, 'image/png' )

   				# let's see if the data uri exists in the file
   				assert css_contents.include?( data_uri )
   			end
	    end
	      
   		should_eventually 'have tests that show that unflagged images are not embedded in final output'
   		should_eventually 'have tests that show that unsupported images are not embedded in final output'


	  end # context

	  context "embed method" do
	    should "not modify regular paths" do
	      path = @supported_assets.first[:path]
	      assert_equal( path, @embedder.embed_data_uri( path ) )
	    end

	    should "not modify paths flagged as not embeddable" do
				path = "#{@supported_assets.first[:path]}?embed=false"
	      assert_equal( path, @embedder.embed_data_uri( path ) )
	    end
	      
	    should "embed image when path flagged as embeddable" do
				path = "#{@supported_assets.first[:path]}?embed=true"
	      assert_not_equal( path, @embedder.embed_data_uri( path ) )
	    end
	      
	    should "encode all supported asset types" do
	      @supported_assets.each do |asset|
	        path = "#{asset[:path]}?embed=true"
	        assert_not_equal( path, @embedder.embed_data_uri( path ) )
	      end
	    end
	    
	    should "not encod unsupported asset types" do
	      @unsupported_assets.each do |asset|
	        path = "#{asset[:path]}?embed=true"
	        assert_equal( path, @embedder.embed_data_uri( path ) )
	      end
	    end
	      
	    should "set correct mimetype for supported extensions" do
	      @supported_assets.each do |asset|
	        path = "#{asset[:path]}?embed=true"
					extension = /(png|gif|jpg|jpeg)/.match( asset[:path] )
	        assert_match(/image\/#{extension}/, @embedder.embed_data_uri( path ) )
	      end
	    end
	  end  # context 
	end
  
	private
	# expects the containing path to have been created already
	def create_files( files = [] )
		files.each do |file|
	   	path = file[:path]
	    File.open(path, 'w') do |f|
	      f.write file[:content]
		    assert File.exists?( file[:path] )
	    end
		end
	end

end
