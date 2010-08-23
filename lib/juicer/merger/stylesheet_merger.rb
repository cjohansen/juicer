#!/usr/bin/env ruby
require "juicer/merger/base"
require "juicer/dependency_resolver/css_dependency_resolver"
require 'pathname'

module Juicer
  module Merger
    # Merge several files into one single output file. Resolves and adds in files
    # from @import statements
    #
    class StylesheetMerger < Base

      # Constructor
      #
      # Options:
      # * <tt>:document_root</tt> - Path to web root if there is any @import statements
      #   using absolute URLs
      #
      def initialize(files = [], options = {})
        @dependency_resolver = CssDependencyResolver.new(options)
        super(files || [], options)
        @hosts = options[:hosts] || []
        @host_num = 0
        @use_absolute = options.key?(:absolute_urls) ? options[:absolute_urls] : false
        @use_relative = options.key?(:relative_urls) ? options[:relative_urls] : false
        @document_root = options[:document_root]
        @document_root = File.expand_path(@document_root).sub(/\/?$/, "") if @document_root # Make sure path doesn't end in a /
      end

     private
      #
      # Takes care of removing any import statements. This avoids importing the
      # file that was just merged into the current file.
      #
      # +merge+ also recalculates any referenced URLs. Relative URLs are adjusted
      # to be relative to the resulting merged file. Absolute URLs are left alone
      # by default. If the :hosts option is set, the absolute URLs will cycle
      # through these. This may help in concurrent downloads.
      #
      # The options hash decides how Juicer recalculates referenced URLs:
      #
      #   options[:absolute_urls] When true, all paths are converted to absolute
      #                           URLs. Requires options[:document_root] to define
      #                           root directory to resolve absolute URLs from.
      #   options[:relative_urls] When true, all paths are converted to relative
      #                           paths. Requires options[:document_root] to define
      #                           root directory to resolve absolute URLs from.
      #
      # If none if these are set then relative URLs are recalculated to match
      # location of merged target while absolute URLs are left absolute.
      #
      # If options[:hosts] is set to an array of hosts, then they will be cycled
      # for all absolute URLs regardless of absolute/relative URL strategy.
      #
      def merge(file)
        content = super.gsub(/^\s*@import(?:\surl\(|\s)(['"]?)([^\?'"\)\s]+)(\?(?:[^'"\)]*))?\1\)?(?:[^?;]*);?/i, "")
        dir = File.expand_path(File.dirname(file))

        content.scan(/url\([\s"']*([^\)"'\s]*)[\s"']*\)/m).uniq.collect do |url|
          url = url.first
          path = resolve_path(url, dir)
          content.gsub!(/\([\s"']*#{url}[\s"']*\)/m, "(#{path})") unless path == url
        end

        content
      end

      #
      # Resolves a path relative to a directory
      #
      def resolve_path(url, dir)
        return url if url =~ /^data:/
        path = url

        # Absolute URLs
        if url =~ %r{^/} && @use_relative
          raise ArgumentError.new("Unable to handle absolute URLs without :document_root option") if !@document_root
          path = Pathname.new(File.join(@document_root, url)).relative_path_from(@root).to_s
        end

        # All URLs that don't start with a protocol
        if url !~ %r{^/} && url !~ %r{^[a-z]+://}
          if @use_absolute || @hosts.length > 0
            raise ArgumentError.new("Unable to handle absolute URLs without :document_root option") if !@document_root
            path = File.expand_path(File.join(dir, url)).sub(@document_root, "")         # Make absolute
          else
            path = Pathname.new(File.join(dir, url)).relative_path_from(@root).to_s # ...or redefine relative ref
          end
        end

        # Cycle hosts, if any
        if path =~ %r{^/} && @hosts.length > 0
          path = File.join(@hosts[@host_num % @hosts.length], path)
          @host_num += 1
        end

        path
      end
    end
  end
end

# Run file from command line
#
if $0 == __FILE__
  puts("Usage: stylesheet_merger.rb file[...] output") and exit if $*.length < 2

  fm = Juicer::Merger::StylesheetMerger.new()
  fm << $*[0..-2]
  fm.save($*[-1])
end
