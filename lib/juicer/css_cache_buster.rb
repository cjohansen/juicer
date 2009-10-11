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
  # When dealing with full URLs (ie including hosts) you can optionally specify
  # an array of hosts to recognize as "local", meaning they serve assets from
  # the :web_root directory. This way even asset host cycling can benefit from
  # cache busters.
  #
  class CssCacheBuster
    include Juicer::Chainable

    def initialize(options = {})
      @web_root = options[:web_root]
      @web_root.sub!(%r{/?$}, "") if @web_root # Remove trailing slash
      @type = options[:type] || :soft
      @hosts = (options[:hosts] || []).collect { |h| h.sub!(%r{/?$}, "") } # Remove trailing slashes
      @contents = nil
    end

    #
    # Update file. If no +output+ is provided, the input file is overwritten
    #
    def save(file, output = nil)
      @contents = File.read(file)
      used = []

      urls(file).each do |url|
        begin
          path = resolve(url, file)
          next if used.include?(path) || ( path.include?( 'data:image/') && path.include?(';base64,') )

          if path != url
            used << path
            basename = File.basename(Juicer::CacheBuster.path(path, @type))
            @contents.gsub!(url, File.join(File.dirname(url), basename))
          end
        rescue Errno::ENOENT
          puts "Unable to locate file #{path || url}, skipping cache buster"
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
        match.first
      end
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
