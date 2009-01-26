require File.expand_path(File.join(File.dirname(__FILE__), "chainable"))
require File.expand_path(File.join(File.dirname(__FILE__), "cache_buster"))

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
  class CssCacheBuster
    include Juicer::Chainable

    def initialize(options = {})
      @web_root = options[:web_root]
      @type = options[:type] || :soft
      @contents = nil
    end

    #
    # Update file. If no +output+ is provided, the input file is overwritten
    #
    def save(file, output = nil)
      @contents = File.read(file)

      urls(file).each do |url|
        @contents.sub!(url, Juicer::CacheBuster.path(resolve(url, file)))
      end

      File.open(output || file, "w") { |f| f.puts @contents }
      @contents = nil
    end

    #
    # Returns all referenced URLs in +file+. Returned paths are absolute (ie,
    # they're resolved relative to the +file+ path.
    #
    def urls(file)
      @contents = File.read(file) unless @contents

      @contents.scan(/url\(([^\)]*)\)/m).collect do |match|
        match.first
      end
    end

    #
    # Resolve full path from URL
    #
    def resolve(target, from)
      return target if target =~ %r{^[a-z]+\://}

      if target =~ %r{^/}
        unless @web_root
          raise FileNotFoundError.new("Unable to resolve absolute path without :web_root option")
        end

        return File.expand_path(File.join(@web_root, target))
      end

      File.expand_path(File.join(File.dirname(File.expand_path(from)), target))
    end
  end
end
