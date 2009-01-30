require File.join(File.dirname(__FILE__), "util")
require "cmdparse"
require "pathname"

module Juicer
  module Command
    # Displays a list of files that make up the dependency chain for the input
    # files/patterns.
    #
    class List < CmdParse::Command
      include Juicer::Command::Util

      # Initializes command
      #
      def initialize(io = STDOUT)
        super('list', false, true)
        @io = io
        self.short_desc = "Lists all dependencies for all input files/patterns"
        self.description = <<-EOF
Dependencies are looked up recursively. The dependency chain reveals which files
will be joined by juicer merge.

Input parameters may be:
  * Single file, ie $ juicer list myfile.css
  * Single glob pattern, ie $ juicer list **/*.css
  * Multiple mixed arguments, ie $ juicer list **/*.js **/*.css
        EOF
      end

      # Execute command
      #
      def execute(args)
        if args.length == 0
          raise ArgumentError.new('Please provide atleast one input file/pattern')
        end

        types = { :js => Juicer::Merger::JavaScriptDependencyResolver.new,
                  :css => Juicer::Merger::CssDependencyResolver.new }

        files(args).each do |file|
          type = file.split(".").pop.to_sym
          raise FileNotFoundError.new("Unable to guess type (CSS/JavaScript) of file #{relative(file)}") unless types[type]

          @io.puts "Dependency chain for #{relative file}:"
          @io.puts "  #{relative(types[type].resolve(file)).join("\n  ")}\n\n"
        end
      end
    end
  end
end
