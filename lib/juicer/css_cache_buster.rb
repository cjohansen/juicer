require "juicer/chainable"
require "juicer/cache_buster"
require "juicer/asset/path_resolver"

module Juicer
  #
  # The CssCacheBuster is a tool that can parse a CSS file and substitute all
  # referenced URLs by a URL appended with a timestamp denoting it's last change.
  # This causes the URLs to be unique every time they've been modified, thus
  # facilitating using a far future expires header on your web server.
  #
  # See Juicer::CacheBuster for more information on how the cache buster URLs
  # work.
  #
  # When dealing with CSS files that reference absolute URLs like /images/1.png
  # you must specify the :web_root option that these URLs should be resolved
  # against.
  #
  # When dealing with full URLs (ie including hosts) you can optionally specify
  # an array of hosts to recognize as "local", meaning they serve assets from
  # the :web_root directory. This way even asset host cycling can benefit from
  # cache busters.
  #
  class CssCacheBuster
    include Juicer::Chainable

    def initialize(options = {})
      @web_root = options[:web_root]
      @web_root.sub!(%r{/?$}, "") if @web_root
      @type = options[:type] || :soft
      @hosts = (options[:hosts] || []).collect { |h| h.sub!(%r{/?$}, "") }
      @contents = nil
      @path_resolver = Juicer::Asset::PathResolver.new(:document_root => options[:web_root],
                                                       :hosts => options[:hosts])
    end

    #
    # Update file. If no +output+ is provided, the input file is overwritten
    #
    def save(file, output = nil)
      @contents = File.read(file)
      @path_resolver = Juicer::Asset::PathResolver.new(:document_root => @web_root,
                                                       :hosts => @hosts,
                                                       :base => File.dirname(file))
      used = []

      urls(file).each do |asset|
        begin
          path = resolve(url, file)
          next if used.include?(path)

          if path != url
            used << path
            basename = File.basename(Juicer::CacheBuster.path(path, @type))
            @contents.gsub!(url, File.join(File.dirname(url), basename))
          end
        rescue Errno::ENOENT
          puts "Unable to locate file #{asset.path}, skipping cache buster"
        rescue ArgumentError => e
          if e.message =~ /No document root/
            raise FileNotFoundError.new("Unable to resolve path #{asset.path} without :web_root option")
          else
            raise e
          end
        end
      end

      File.open(output || file, "w") { |f| f.puts @contents }
      @contents = nil
    end

    chain_method :save

    #
    # Returns all referenced URLs in +file+. Returned paths are absolute (ie,
    # they're resolved relative to the +file+ path.
    #
    def urls(file)
      @contents = File.read(file) unless @contents

      @contents.scan(/url\([\s"']*([^\)"'\s]*)[\s"']*\)/m).collect do |match|
        @path_resolver.resolve(match.first)
      end
    end
  end
end
