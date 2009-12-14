# -*- coding: utf-8 -*-

require "juicer/asset/path"

module Juicer
  module Asset
    #
    # Factory class that creates <tt>Juicer::Asset::Path</tt> objects from a common set of
    # options. Also facilitates asset host cycling on a set of asset paths.
    #
    #   path_resolver = Juicer::Asset::PathResolver.new(
    #                     :document_root => "/var/www",
    #                     :hosts => ["assets1.mysite.com", "assets2.mysite.com"]
    #                   )
    #
    #   asset = path_resolver.resolve("../images/logo.png")
    #   asset.document_root
    #   #=> "/var/www"
    #   
    #   asset.absolute_path(path_resolver.cycle_hosts)
    #   #=> "http://assets1.mysite.com/images/logo.png"
    #   
    #   asset = path_resolver.resolve("/favicon.ico")
    #   asset.absolute_path(path_resolver.cycle_hosts)
    #   #=> "http://assets2.mysite.com/favicon.ico"
    #
    # Author::    Christian Johansen (christian@cjohansen.no)
    # Copyright:: Copyright (c) 2009 Christian Johansen
    # License::   BSD
    #
    class PathResolver
      attr_reader :hosts, :document_root, :base

      #
      # Initialize resolver. All options set on the resolver will be carried on to the
      # resolved assets.
      #
      def initialize(options = {})
        options[:base] ||= Dir.pwd
        @options = options
        @base = options[:base]
        @hosts = Juicer::Asset::Path.hosts_with_scheme(options[:hosts]) || []
        @current_host = 0
        @document_root = @options[:document_root]
      end

      #
      # Returns a <tt>Juicer::Asset::Path</tt> object for the given path, and the options
      # set on the resolver.
      #
      def resolve(path)
        Juicer::Asset::Path.new(path, @options)
      end

      #
      # Set new base directory. Will affect any assets resolved from here, but any
      # assets previously resolved will not be changed
      #
      def base=(base)
        @base = base
        @options[:base] = base
      end

      #
      # Cycle asset hosts. Returns an asset host
      #
      def cycle_hosts
        return nil if @hosts.length == 0

        host = @hosts[@current_host % @hosts.length]
        @current_host += 1

        host
      end

      alias host cycle_hosts
    end
  end
end
