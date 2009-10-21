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
  # FIXME:
  # Add details on pros and cons of using embedded images
  # 
  class ImageEmbed
    include Juicer::Chainable

    # The maximum supported limit for modern browsers, See the Readme.rdoc for details
    SIZE_LIMIT = 32768
    
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
    end

    #
    # Update file. If no +output+ is provided, the input file is overwritten
    #
    def save(file, output = nil)
			if ( @type == :data_uri )
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
  	            @contents.gsub!(url, embed_data_uri( path ) )
              else
                Juicer::LOGGER.warn("The final data uri for the image located at #{path.gsub('?embed=true', '')} exceeds #{SIZE_LIMIT} and will not be embedded to maintain compatability.") 
              end
	          end
	        rescue Errno::ENOENT
	          puts "Unable to locate file #{path || url}, skipping image embedding"
	        end
	      end

	      File.open(output || file, "w") { |f| f.puts @contents }
	      @contents = nil
			end
    end

    chain_method :save
    
    def embed_data_uri( path )
      new_path = path
      if path.match( /\?embed=true$/ )
        supported_file_matches = path.match( /(?:\.)(png|gif|jpg|jpeg)(?:\?embed=true)$/i )
        filetype = supported_file_matches[1] if supported_file_matches
        if ( filetype )        
          filename = path.gsub('?embed=true','')
        
          # check if file exists, throw an error if it doesn't exist
          if File.exist?( filename )
            # read contents of file into memory              
            content = File.read( filename )
            content_type = "image/#{filetype}"

            # encode the url
            new_path = Datafy::make_data_uri( content, content_type )
          else
            puts "Unable to locate file #{filename} on local file system, skipping image embedding"
          end
        end
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