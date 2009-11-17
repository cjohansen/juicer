require File.expand_path(File.join(File.dirname(__FILE__), "chainable"))
require File.expand_path(File.join(File.dirname(__FILE__), "cache_buster"))

module Juicer
  #
  # The ImageEmbed is a tool that can parse a CSS file and substitute all
  # referenced URLs by a either a data uri or MHTML equivalent
  # 
  # - data uri (http://en.wikipedia.org/wiki/Data_URI_scheme)
  # - MHTML (http://en.wikipedia.org/wiki/MHTML)
  # 
  # Only local resources will be processed this way, external resources referenced
  # by absolute urls will be left alone
  # 
  class ImageEmbed
    include Juicer::Chainable

    # The maximum supported limit for modern browsers, See the Readme.rdoc for details
    SIZE_LIMIT = 32768

    MHTML_START     = "/*\r\nContent-Type: multipart/related; boundary=\"MHTML\"\r\n\r\n"
    MHTML_SEPARATOR = "--MHTML\r\n"
    MHTML_END       = "*/\r\n"
    
    #
    # Returns the size limit
    #
    def size_limit
      SIZE_LIMIT
    end

    def initialize(options = {})
      @web_root = options[:web_root]
      @web_root.sub!(%r{/?$}, "") if @web_root # Remove trailing slash
      @type = options[:type] || :none
      @contents = nil
      @relative_path = options[:relative_path]
    end

    #
    # Update file. If no +output+ is provided, the input file is overwritten
    #
    def save(file, output = nil)
			if ( @type == :data_uri || @type == :mhtml )
			  output_file = output || file
			  @mhtml_encoded_images = []
	      @contents = File.read(file)
	      used = []

				# TODO: Remove "?embed=true" from duplicate urls
				duplicates = duplicate_urls( file )
				if duplicates.length > 0
					Juicer::LOGGER.warn("Duplicate image urls detected, these images will not be embedded: #{duplicates.collect { |v| v.gsub('?embed=true', '') }.inspect}") 
				end

				usable_urls = distinct_urls_without_duplicates( file )
	      usable_urls.each do |url|
	        begin
	          path = resolve(url, file)
	          next if used.include?(path)

	          if path != url
	            used << path            
	            
              # make sure we do not exceed SIZE_LIMIT
              new_path = embed_data_uri( path )
              
              if ( new_path.length < SIZE_LIMIT )
  	            # replace the url in the css file with the data uri
  	            @contents.gsub!(url, embed_data_uri( path ) ) if @type == :data_uri
  	            @contents.gsub!(url, embed_mhtml( path, output_file ) ) if @type == :mhtml
              else
                Juicer::LOGGER.warn("The final data uri for the image located at #{path.gsub('?embed=true', '')} exceeds #{SIZE_LIMIT} and will not be embedded to maintain compatability.") 
              end
	          end
	        rescue Errno::ENOENT
	          puts "Unable to locate file #{path || url}, skipping image embedding"
	        end
	      end
	      
	      if @mhtml_encoded_images.length > 0
	        mhtml = []
          @mhtml_encoded_images.each_index do |index|
            image = @mhtml_encoded_images[index]
            mhtml << 
            [ 
              MHTML_SEPARATOR, 
              "Content-Location: image#{index}\r\n", 
              "Content-Type: #{image[:content_type]}\r\n",
              "Content-Transfer-Encoding: base64\r\n\r\n", image[:content], "\r\n"
            ]
          end	        
          @contents = [MHTML_START, mhtml, MHTML_END, @contents].flatten.join('')

          puts @contents
        end

	      File.open( output_file, "w") { |f| f.puts @contents }
	      @contents = nil
			end
    end

    chain_method :save
        
    def image_supported?( css_path )
      filename = filename_from_embed_path( css_path )
      valid_image = css_path.match( /(?:\.)(png|gif|jpg|jpeg)(?:\?embed=true)$/i ) || nil
      if ( valid_image )
        if File.exist?( filename )
          return true
        else
          puts "Unable to locate file #{filename} on local file system, skipping image"  
          return false
        end
      end
    end

    # trims '?embed=true' from filenames
    def filename_from_embed_path( css_path )
      css_path.gsub('?embed=true','')
    end
    
    def embed_data_uri( path )
      new_path = path
      if image_supported?( path )
        filename = filename_from_embed_path( path )
        filetype = filename.match( /(?:\.)(png|gif|jpg|jpeg)$/i )[1]
        
        # read contents of file into memory
        content = File.read( filename )
        content_type = "image/#{filetype}"

        # encode the url
        new_path = Datafy::make_data_uri( content, content_type )
      end
      return new_path
    end

    # translates a path into an MHTML path statement and adds the Base64 
    # encoded image to the @mhtml_encoded_images collection
    def embed_mhtml( path, output_file )
      new_path = path
      if image_supported?( path )
        filename = filename_from_embed_path( path )
        filetype = filename.match( /(?:\.)(png|gif|jpg|jpeg)$/i )[1]
      
        # read contents of file into memory
        content = File.read( filename )
        content_type = "image/#{filetype}"
        
        new_path = "mhtml:/#{@relative_path}!image#{@mhtml_encoded_images.length}"

        @mhtml_encoded_images << {
          :content => Base64.encode64(content).gsub("\n", ''),
          :content_type => content_type
        }
      end
      return new_path
    end

    #
    # Returns all referenced URLs in +file+. Returned paths are absolute (ie,
    # they're resolved relative to the +file+ path.
    #
    def urls(file)
      @contents = File.read(file) unless @contents

      @contents.scan(/url\([\s"']*([^\)"'\s]*)[\s"']*\)/m).collect do |match|
        match.first
      end
    end

		def distinct_urls_without_duplicates( file )
			urls(file) - duplicate_urls(file)
		end

		def duplicate_urls( file )
			urls(file).duplicates
		end

    #
    # Resolve full path from URL
    #
    def resolve(target, from)
      # If URL is external, check known hosts to see if URL can be treated
      # like a local one (ie so we can add cache buster)
      catch(:continue) do
        if target =~ %r{^[a-z]+\://}
          # This could've been a one-liner, but I prefer to be
          # able to read my own code ;)
          @hosts.each do |host|
            if target =~ /^#{host}/
              target.sub!(/^#{host}/, "")
              throw :continue
            end
          end

          # No known hosts matched, return
          return target
        end
      end

      # Simply add web root to absolute URLs
      if target =~ %r{^/}
        raise FileNotFoundError.new("Unable to resolve absolute path #{target} without :web_root option") unless @web_root
        return File.expand_path(File.join(@web_root, target))
      end

      # Resolve relative URLs to full paths
      File.expand_path(File.join(File.dirname(File.expand_path(from)), target))
    end
  end
end

# http://snippets.dzone.com/posts/show/3838
module Enumerable
  def duplicates
    inject({}) {|h,v| h[v]=h[v].to_i+1; h}.reject{|k,v| v==1}.keys
  end
end