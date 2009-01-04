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
        super(files, options)
      end

     private
      def merge(file)
        content = super.gsub(/^\s*\@import\s("|')(.*)("|')\;?/, '')
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
