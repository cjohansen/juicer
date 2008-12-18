#!/usr/bin/env ruby
['file_merger', 'css_import_resolver'].each do |lib|
  require File.expand_path(File.join(File.dirname(__FILE__), lib))
end

module Juicer
  module Merger
    # Merge several files into one single output file. Resolves and adds in files
    # from @import statements
    #
    class CssFileMerger < FileMerger

      # Constructor
      #
      def initialize(options = {})
        super(options)
        @dependency_resolver = CssImportResolver.new
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
  if $*.length < 2
    puts 'Usage: css_file_merger.rb file[...] output'
  else
    fm = Juicer::Merger::CssFileMerger.new()
    fm << $*[0..-2]
    fm.save($*[-1])
  end
end
