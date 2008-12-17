#!/usr/bin/env ruby
['file_merger', 'javascript_dependency_resolver'].each do |lib|
  require File.expand_path(File.join(File.dirname(__FILE__), lib))
end

module Juicer
  module Merger
    # Merge several files into one single output file. Resolves and adds in files from @depend comments
    class JavaScriptFileMerger < FileMerger

      # Constructor
      def initialize(options = {})
        super(options)
        @dependency_resolver = JavaScriptDependencyResolver.new
      end
    end
  end
end

# Run file from command line
# TODO: Refactor to testable Juicer::Merger::JavaScript::FileMerger.cli method
# or similar.
#
if $0 == __FILE__
  return if $*.length < 2

  fm = JavaScriptFileMerger.new()
  fm << $*[0..-2]
  fm.save($*[-1])
end
