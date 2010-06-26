require "test_helper"
require 'fakefs/safe'

class TestImageEmbed < Test::Unit::TestCase
  include FakeFS

  context "ImageEmbed instance using data_uri," do
    setup do
      FakeFS.activate!
      FileSystem.clear
      FileUtils.mkdir_p("/stylesheets")
      FileUtils.mkdir_p("/images")

      @supported_assets = [
                           { :path => '/images/test.png', :content => 'hello png!' },
                           { :path => '/images/test.gif', :content => 'hello gif!' },
                           {  :path => '/images/test.jpg', :content => 'hello jpg!' },
                           { :path => '/images/test.jpeg', :content => 'hello jpeg!' },
                          ]
      create_files(@supported_assets)

      @unsupported_assets = [
                             { :path => '/images/test.bmp', :content => 'hello bmp!' },
                             { :path => '/images/test.js', :content => 'hello js!' },
                             { :path => '/images/test.txt', :content => 'hello txt!' },
                             { :path => '/images/test.swf', :content => 'hello swf!' },
                             { :path => '/images/test.swf', :content => 'hello swf!' },
                             { :path => '/images/test.ico', :content => 'hello ico!' },
                             { :path => '/images/test.tif', :content => 'hello tif!' },
                             { :path => '/images/test.tiff', :content => 'hello tiff!' },
                             { :path => '/images/test.applet', :content => 'hello applet!' },
                             { :path => '/images/test.jar', :content => 'hello jar!' }
                            ]
      create_files(@unsupported_assets)
      @embedder = Juicer::ImageEmbed.new(:type => :data_uri, :document_root => '')
    end

    teardown do
      FakeFS.deactivate!
    end

    context "save method" do
      context "with files exceeding SIZE_LIMIT" do
        setup do
          @large_files = [{ :path => '/images/large-file.png',
                            :content => "hello png!" + (" " * @embedder.size_limit) }]
          create_files(@large_files)

          @stylesheets = [{
                            :path => '/stylesheets/test_embed_duplicates.css',
                            :content => "body: { background: url(#{@large_files.first[:path]}?embed=true); }"
                          }]
          create_files(@stylesheets)
        end

        should "not embed images that exceeds size limit" do
          # make sure there are no errors
          assert_nothing_raised do
            @embedder.save @stylesheets.first[:path]
          end

          css_contents = File.read(@stylesheets.first[:path])

          # encode the image
          image_contents = File.read( @large_files.first[:path] )
          data_uri = Datafy::make_data_uri(image_contents, 'image/png')

          # make sure the encoded data_uri is not present in the stylesheet
          assert !css_contents.include?(data_uri)

          # make sure the original url still exist in the stylesheet
          assert_match Regexp.new(@large_files.first[:path]), css_contents
        end
      end

      context "non empty document root" do
        setup do
          @document_root = '/path/to/public/dir'
          @another_embedder = Juicer::ImageEmbed.new(:type => :data_uri, :document_root => @document_root)
          @files = [{ :path => "#{@document_root}/images/custom-file.png", :filename => '/images/custom-file.png', :content => "hello png!" }]
          create_files(@files)
        end
        
        should "embed urls with embedder" do
          stylesheets = [{ :path => "#{@document_root}/stylesheets/test_absolute_path.css", :content => "body: { background: url(#{@files.first[:filename]}?embed=true); }" }]
          create_files(stylesheets)
          
          @another_embedder.save stylesheets.first[:path]
          css_contents = File.read(stylesheets.first[:path])

          # encode the image
          image_contents = File.read(@files.first[:path])
          data_uri = Datafy::make_data_uri(image_contents, 'image/png')

          # make sure the encoded data_uri is present in the stylesheet
          assert css_contents.include?(data_uri)
        end
        
        should "not embed urls with embedder" do
          stylesheets = [{ :path => "#{@document_root}/stylesheets/test_absolute_path.css", :content => "body: { background: url(#{@files.first[:filename]}?embed=false); }" }]
          create_files(stylesheets)
          
          @another_embedder.save stylesheets.first[:path]
          css_contents = File.read(stylesheets.first[:path])

          # encode the image
          assert css_contents.include?(@files.first[:filename])
        end
      end

      context "with duplicated urls" do
        setup do
          @stylesheets = [{
                            :path => '/stylesheets/test_embed_duplicates.css',
                            :content => <<-EOF
         body: { background: url(#{@supported_assets.first[:path]}?embed=true); }
         div.section: { background: url(#{@supported_assets.first[:path]}?embed=true); }
         div.article: { background: url(#{@supported_assets.last[:path]}?embed=true); }
                            EOF
                          }]
          create_files(@stylesheets)
        end

        should_eventually "provide warnings for duplicate urls"

        should "not embed duplicates" do
          # make sure there are no errors
          assert_nothing_raised do
            @embedder.save @stylesheets.first[:path]
          end

          css_contents = File.read(@stylesheets.first[:path])

          # encode the image
          image_contents = File.read(@supported_assets.first[:path])
          data_uri = Datafy::make_data_uri(image_contents, 'image/png')

          # make sure the encoded data_uri is not present in the stylesheet
          assert !css_contents.include?(data_uri)
        end

        should "embed distinct urls" do
          # make sure there are no errors
          assert_nothing_raised do
            @embedder.save @stylesheets.first[:path]
          end

          css_contents = File.read(@stylesheets.first[:path])

          # encode the image
          image_contents = File.read(@supported_assets.last[:path])
          data_uri = Datafy::make_data_uri(image_contents, 'image/jpeg')

          # make sure the encoded data_uri is not present in the stylesheet
          assert css_contents.include?(data_uri)

          assert_no_match Regexp.new(@supported_assets.last[:path]), css_contents
        end

      end

      should "embed images into css file" do
        @stylesheets = [
                        {
                          :path => '/stylesheets/test_embed_true.css',
                          :content => "body: { background: url(#{@supported_assets.first[:path]}?embed=true); }"
                        }
                       ]
        create_files( @stylesheets )

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

      should "not embed unflagged images" do
        @stylesheets = [
                        {
                          :path => '/stylesheets/test_embed_true.css',
                          :content => "
        body: { background: url(#{@supported_assets.first[:path]}); }
        h1: { background: url(#{@supported_assets.last[:path]}?embed=false); }
      "
                        }
                       ]
        create_files( @stylesheets )

        @stylesheets.each do |stylesheet|
          old_contents = File.read( stylesheet[:path] )

          # make sure there are no errors
          assert_nothing_raised do
            @embedder.save stylesheet[:path]
          end

          css_contents = File.read( stylesheet[:path] )

          # make sure the original url still exists
          assert_match( Regexp.new( @supported_assets.first[:path] ), css_contents )
          assert_match( Regexp.new( @supported_assets.last[:path] ), css_contents )
        end
      end


      should "not embed unsupported images" do
        @stylesheets = [
                        {
                          :path => '/stylesheets/test_embed_true.css',
                          :content => "
        body: { background: url(#{@unsupported_assets.first[:path]}?embed=true); }
        h1: { background: url(#{@unsupported_assets.last[:path]}?embed=true); }
      "
                        }
                       ]
        create_files( @stylesheets )

        @stylesheets.each do |stylesheet|
          old_contents = File.read( stylesheet[:path] )

          # make sure there are no errors
          assert_nothing_raised do
            @embedder.save stylesheet[:path]
          end

          css_contents = File.read( stylesheet[:path] )

          # make sure the original url still exists
          assert_match( Regexp.new( @unsupported_assets.first[:path] ), css_contents )
          assert_match( Regexp.new( @unsupported_assets.last[:path] ), css_contents )
        end
      end


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
