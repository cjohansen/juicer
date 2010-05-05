require "juicer/chainable"
require "juicer/cache_buster"
require "juicer/asset/path_resolver"

module Juicer
  #
  # The ImageEmbed is a tool that can parse a CSS file and substitute all
  # referenced URLs by a data uri
  # 
  # - data uri (http://en.wikipedia.org/wiki/Data_URI_scheme)
  # 
  # Only local resources will be processed this way, external resources referenced
  # by absolute urls will be left alone
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
      @document_root = options[:document_root]
      @document_root.sub!(%r{/?$}, "") if @document_root # Remove trailing slash
      @type = options[:type] || :none
      @contents = nil
      @hosts = options[:hosts]
      @path_resolver = Juicer::Asset::PathResolver.new(:document_root => options[:document_root],
                                                       :hosts => options[:hosts])
    end

    #
    # Update file. If no +output+ is provided, the input file is overwritten
    #
    def save(file, output = nil)
      return unless @type == :data_uri

      output_file = output || file
      @contents = File.read(file)
      used = []

      @path_resolver = Juicer::Asset::PathResolver.new(:document_root => @document_root,
                                                       :hosts => @hosts,
                                                       :base => File.dirname(file))

      assets = urls(file)

      # TODO: Remove "?embed=true" from duplicate urls
      duplicates = duplicate_urls(assets)

      if duplicates.length > 0
        Juicer::LOGGER.warn("Duplicate image urls detected, these images will not be embedded: #{duplicates.collect { |v| v.gsub('?embed=true', '') }.inspect}") 
      end

      assets.each do |asset|
        begin
          next if used.include?(asset) || duplicates.include?(asset.path)
          used << asset
          
          # make sure we do not exceed SIZE_LIMIT
          new_path = embed_data_uri(asset.filename)

          if new_path.length < SIZE_LIMIT
            # replace the url in the css file with the data uri
            @contents.gsub!(asset.path, embed_data_uri(asset.filename)) if asset.filename.match( /\?embed=true$/ )
          else
            Juicer::LOGGER.warn("The final data uri for the image located at #{asset.path.gsub('?embed=true', '')} exceeds #{SIZE_LIMIT} and will not be embedded to maintain compatability.") 
          end
        rescue Errno::ENOENT
          puts "Unable to locate file #{asset.path}, skipping image embedding"
        end
      end

      File.open(output || file, "w") { |f| f.puts @contents }
      @contents = nil
    end

    chain_method :save
            
    def embed_data_uri( path )
      new_path = path
      
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
      return new_path
    end

    #
    # Returns all referenced URLs in +file+.
    #
    def urls(file)
      @contents = File.read(file) unless @contents

      @contents.scan(/url\([\s"']*([^\)"'\s]*)[\s"']*\)/m).collect do |match|
        @path_resolver.resolve(match.first)
      end
    end

    private
    def duplicate_urls(urls)
      urls.inject({}) { |h,v| h[v.path] = h[v.path].to_i+1; h }.reject{ |k,v| v == 1 }.keys
    end
  end
end
