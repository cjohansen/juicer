#!/usr/bin/env ruby

module Juicer
  module Merger
    # Resolves @depends and @depend statements in comments in JavaScript files.
    # Currently only the first comment in a JavaScript file is parsed
    class JavaScriptDependencyResolver
      attr_reader :files

      # Constructor
      def initialize(options = {})
        @files = []
      end

      def resolve(file)
        imported_file = nil
        @files = []

        IO.foreach(file) do |line|
          if line =~ /\@depends?\s+([^\s\'\"\;]+)/
            imported_file = File.expand_path(File.join(File.dirname(file), $1))
            @files << imported_file if yield imported_file
          else
            # If we have already skimmed through some @depend/@depends or a
            # closing comment we're done.
            break unless imported_file.nil? || !(line =~ /\*\//)
          end
        end

        @files << File.expand_path(file) if yield File.expand_path(file)
        return @files
      end
    end
  end
end
