#!/usr/bin/env ruby
['base', 'css_dependency_resolver'].each do |lib|
  require File.expand_path(File.join(File.dirname(__FILE__), lib))
end

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
      # * <tt>:web_root</tt> - Path to web root if there is any @import statements
      #   using absolute URLs
      #
      def initialize(files = [], options = {})
        @dependency_resolver = CssDependencyResolver.new(options)
        super(files || [], options)
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
      def merge(file)
        content = super.gsub(/^\s*\@import\s("|')(.*)("|')\;?/, '')
        dir = File.expand_path(File.dirname(file))
        i = 0

        content.scan(/url\(([^\)]*)\)/).collect do |url|
          url = path = url.first
          hosts = @options[:hosts] || []

          if url =~ %r{^/} && hosts.length > 0
            path = File.join(hosts[i % hosts.length], url)
            i += 1
          else
            path = Pathname.new(File.join(dir, url)).relative_path_from(@root)
          end

          content.gsub!(/\(#{url}\)/m, "(#{path})") unless path == url
        end

        content
      end
    end
  end
end

# Run file from command line
#
if $0 == __FILE__
  return puts("Usage: stylesheet_merger.rb file[...] output") if $*.length < 2

  fm = Juicer::Merger::StylesheetMerger.new()
  fm << $*[0..-2]
  fm.save($*[-1])
end
