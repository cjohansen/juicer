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
  # you must specify the :document_root option that these URLs should be resolved
  # against.
  #
  # When dealing with full URLs (ie including hosts) you can optionally specify
  # an array of hosts to recognize as "local", meaning they serve assets from
  # the :document_root directory. This way even asset host cycling can benefit from
  # cache busters.
  #
  class CssCacheBuster
    include Juicer::Chainable

    def initialize(options = {})
      @document_root = options[:document_root]
      @document_root.sub!(%r{/?$}, "") if @document_root
      @type = options[:type] || :soft
      @hosts = (options[:hosts] || []).collect { |h| h.sub!(%r{/?$}, "") }
      @contents = @base = nil
    end

    #
    # Update file. If no +output+ is provided, the input file is overwritten
    #
    def save(file, output = nil)
      @contents = File.read(file)
      self.base = File.dirname(file)
      used = []

      urls(file).each do |asset|
        begin
          next if used.include?(asset.path)
          @contents.gsub!(asset.path, asset.path(:cache_buster_type => @type))
          used.push(asset.path)
        rescue Errno::ENOENT
          puts "Unable to locate file #{asset.path}, skipping cache buster"
        rescue ArgumentError => e
          if e.message =~ /No document root/
            puts "Unable to resolve path #{asset.path} without :document_root option"
          else
            puts "Unable to locate #{asset.path}, skipping cache buster"
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
        path_resolver.resolve(match.first)
      end
    end

    protected
    def base=(base)
      @prev_base = @base
      @base = base
    end

    def path_resolver
      return @path_resolver if @path_resolver && @base == @prev_base

      @path_resolver = Juicer::Asset::PathResolver.new(:document_root => @document_root,
                                                       :hosts => @hosts,
                                                       :base => @base)
    end
  end
end
