#!/usr/bin/env ruby
require "juicer/merger/base"
require "juicer/dependency_resolver/javascript_dependency_resolver"

module Juicer
  module Merger
    # Merge several files into one single output file. Resolves and adds in files from @depend comments
    class JavaScriptMerger < Base

      # Constructor
      def initialize(files = [], options = {})
        @dependency_resolver = JavaScriptDependencyResolver.new(options)
        super(files, options)
      end
    end
  end
end

# Run file from command line
# TODO: Refactor to testable Juicer::Merger::JavaScript::FileMerger.cli method
# or similar.
#
if $0 == __FILE__
  puts("Usage: javascript_merger.rb file[...] output") and exit if $*.length < 2

  fm = JavaScriptMerger.new()
  fm << $*[0..-2]
  fm.save($*[-1])
end
