# -*- coding: utf-8 -*-

require "pathname"
require "juicer/cache_buster"

module Juicer
  module Asset
    #
    # Assets are files used by CSS and JavaScript files. The Asset class provides
    # tools for manipulating asset paths, such as rebasing, adding cache busters,
    # and cycling asset hosts.
    #
    # Asset::Path objects are most commonly created by <tt>Juicer::Asset::PathResolver#resolve</tt>
    # which resolves include paths to file names. It is possible, however, to use
    # the asset class directly:
    #
    #   Dir.pwd
    #   #=> "/home/christian/projects/mysite/design/css"
    #   
    #   asset = Juicer::Asset::Path.new "../images/logo.png"
    #   asset.path
    #   #=> "../images/logo.png"
    #   
    #   asset.rebase("~/projects/mysite/design").path
    #   #=> "images/logo.png"
    #   
    #   asset.filename
    #   #=> "/home/christian/projects/mysite/design/images/logo.png"
    #   
    #   asset.path(:cache_buster_type => :soft)
    #   #=> "../images/logo.png?jcb=1234567890"
    #   
    #   asset.path(:cache_buster_type => :soft, :cache_buster => nil)
    #   #=> "../images/logo.png?1234567890"
    #   
    #   asset.path(:cache_buster => "bustIT")
    #   #=> "../images/logo.png?bustIT=1234567890"
    #   
    #   asset = Juicer::Asset::Path.new "../images/logo.png", :document_root
    #   #=> "/home/christian/projects/mysite"
    #   
    #   asset.absolute_path(:cache_buster_type => :hard)
    #   #=> "/images/logo-jcb1234567890.png"
    #   
    #   asset.absolute_path(:host => "http://localhost")
    #   #=> "http://localhost/images/logo.png"
    #   
    #   asset.absolute_path(:host => "http://localhost", :cache_buster_type => :hard)
    #   #=> "http://localhost/images/logo-jcb1234567890.png"
    #
    #
    # Author::    Christian Johansen (christian@cjohansen.no)
    # Copyright:: Copyright (c) 2009 Christian Johansen
    # License::   BSD
    #
    class Path
      # Base directory to resolve relative path from, see Juicer::Asset::Path#initialize
      attr_reader :base

      # Hosts served from <tt>:document_root</tt>, see Juicer::Asset::Path#initialize
      attr_reader :hosts

      # Directory served as root through a web server, see Juicer::Asset::Path#initialize
      attr_reader :document_root

      @@scheme_pattern = %r{^[a-zA-Z]{3,5}://}

      #
      # Initialize asset at <tt>path</tt>. Accepts an optional hash of options:
      #
      # [<tt>:base</tt>]
      #     Base context from which asset is required. Given a <tt>path</tt> of
      #     <tt>../images/logo.png</tt> and a <tt>:base</tt> of <tt>/project/design/css</tt>,
      #     the asset file will be assumed to live in <tt>/project/design/images/logo.png</tt>
      #     Defaults to the current directory.
      # [<tt>:hosts</tt>]
      #     Array of host names that are served from <tt>:document_root</tt>. May also
      #     include scheme/protocol. If not, http is assumed.
      # [<tt>:document_root</tt>]
      #     The root directory for absolute URLs (ie, the server's document root). This
      #     option is needed when resolving absolute URLs that include a hostname as well
      #     as when generating absolute paths.
      #
      def initialize(path, options = {})
        @path = path
        @filename = nil
        @absolute_path = nil
        @relative_path = nil
        @path_has_host = @path =~ @@scheme_pattern
        @path_is_absolute = @path_has_host || @path =~ /^\//

        # Options
        @base = options[:base] || Dir.pwd
        @document_root = options[:document_root]
        @hosts = Juicer::Asset::Path.hosts_with_scheme(options[:hosts])
      end

      #
      # Returns absolute path calculated using the <tt>#document_root</tt>.
      # Optionally accepts a hash of options:
      #
      # [<tt>:host</tt>] Return fully qualified URL with this host name. May include
      #                  scheme/protocol. Default scheme is http.
      # [<tt>:cache_buster</tt>] The parameter name for the cache buster.
      # [<tt>:cache_buster_type</tt>] The kind of cache buster to add, <tt>:soft</tt>
      #                               or <tt>:hard</tt>.
      #
      # A cache buster will be added if either (or both) of the <tt>:cache_buster</tt>
      # or <tt>:cache_buster_type</tt> options are provided. The default cache buster
      # type is <tt>:soft</tt>.
      #
      # Raises an ArgumentException if no <tt>document_root</tt> has been set.
      #
      def absolute_path(options = {})
        if !@absolute_path
          # Pre-conditions
          raise ArgumentError.new("No document root set") if @document_root.nil?

          @absolute_path = filename.sub(%r{^#@document_root}, '').sub(/^\/?/, '/')
          @absolute_path = "#{Juicer::Asset::Path.host_with_scheme(options[:host])}#@absolute_path"
        end

        path_with_cache_buster(@absolute_path, options)
      end

      #
      # Return path relative to <tt>#base</tt>
      #
      # Accepts an optional hash of options for cache busters:
      #
      # [<tt>:cache_buster</tt>] The parameter name for the cache buster.
      # [<tt>:cache_buster_type</tt>] The kind of cache buster to add, <tt>:soft</tt>
      #                               or <tt>:hard</tt>.
      #
      # A cache buster will be added if either (or both) of the <tt>:cache_buster</tt>
      # or <tt>:cache_buster_type</tt> options are provided. The default cache buster
      # type is <tt>:soft</tt>.
      #
      def relative_path(options = {})
        @relative_path ||= Pathname.new(filename).relative_path_from(Pathname.new(base)).to_s
        path_with_cache_buster(@relative_path, options)
      end

      #
      # Returns the original path.
      #
      # Accepts an optional hash of options for cache busters:
      #
      # [<tt>:cache_buster</tt>] The parameter name for the cache buster.
      # [<tt>:cache_buster_type</tt>] The kind of cache buster to add, <tt>:soft</tt>
      #                               or <tt>:hard</tt>.
      #
      # A cache buster will be added if either (or both) of the <tt>:cache_buster</tt>
      # or <tt>:cache_buster_type</tt> options are provided. The default cache buster
      # type is <tt>:soft</tt>.
      #
      def path(options = {})
        path_with_cache_buster(@path, options)
      end

      #
      # Return filename on disk. Requires the <tt>#document_root</tt> to be set if
      # original path was an absolute one.
      #
      # If asset path includes scheme/protocol and host, it can only be resolved if
      # a match is found in <tt>#hosts</tt>. Otherwise, an exeception is raised.
      #
      def filename
        return @filename if @filename

        # Pre-conditions
        raise ArgumentError.new("No document root set") if @path_is_absolute && @document_root.nil?
        raise ArgumentError.new("No hosts served from document root") if @path_has_host && @hosts.empty?

        path = strip_host(@path)
        raise ArgumentError.new("No matching host found for #{@path}") if path =~ @@scheme_pattern

        dir = @path_is_absolute ? document_root : base
        @filename = File.expand_path(File.join(dir, path))
      end

      #
      # Rebase path and return a new Asset::Path object.
      #
      #   asset = Juicer::Asset::Path.new "../images/logo.png", :base => "/var/www/public/stylesheets"
      #   asset2 = asset.rebase("/var/www/public")
      #   asset2.relative_path #=> "images/logo.png"
      #
      def rebase(base_path)
        path = Pathname.new(filename).relative_path_from(Pathname.new(base_path)).to_s

        Juicer::Asset::Path.new(path,
                                :base => base_path,
                                :hosts => hosts,
                                :document_root => document_root)
      end

      #
      # Returns basename of filename on disk
      #
      def basename
        File.basename(filename)
      end

      #
      # Returns basename of filename on disk
      #
      def dirname
        File.dirname(filename)
      end

      #
      # Returns <tt>true</tt> if file exists on disk
      #
      def exists?
        File.exists?(filename)
      end

      #
      # Accepts a single host, or an array of hosts and returns an array of hosts
      # that include scheme/protocol, and don't have trailing slash.
      #
      def self.hosts_with_scheme(hosts)
        hosts.nil? ? [] : [hosts].flatten.collect { |host| self.host_with_scheme(host) }
      end

      #
      # Assures that a host has scheme/protocol and no trailing slash
      #
      def self.host_with_scheme(host)
        return host if host.nil?
        (host !~ @@scheme_pattern ? "http://#{host}" : host).sub(/\/$/, '')
      end

      private
      #
      # Adds cache buster to paths if :cache_buster_type and :cache_buster indicates
      # they should be added.
      #
      def path_with_cache_buster(path, options = {})
        return path if !options.key?(:cache_buster) && options[:cache_buster_type].nil?

        buster_path = nil
        type = options[:cache_buster_type] || :soft

        if options.key?(:cache_buster)
          # Pass :cache_buster even if it's nil
          buster_path = Juicer::CacheBuster.send(type, filename, options[:cache_buster])
        else
          # If :cache_buster wasn't specified, rely on default value
          buster_path = Juicer::CacheBuster.send(type, filename)
        end

        path.sub(File.basename(path), File.basename(buster_path))
      end

      #
      # Strip known hosts from path
      #
      def strip_host(path)
        hosts.each do |host|
          return path if path !~ @@scheme_pattern

          path.sub!(%r{^#{host}}, '')
        end

        return path
      end
    end
  end
end
