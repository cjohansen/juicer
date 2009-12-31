require "juicer/command/util"
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
      def initialize(log = nil)
        super('list', false, true)
        @log = log
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

        types = { :js => Juicer::JavaScriptDependencyResolver.new,
                  :css => Juicer::CssDependencyResolver.new }

        result = files(args).map { |file|
          type = file.split(".").pop.to_sym
          raise FileNotFoundError.new("Unable to guess type (CSS/JavaScript) of file #{relative(file)}") unless types[type]

          deps = relative types[type].resolve(file)
          # there may only be one dependency, which resolve() returns as a string
          deps = deps.join("\n  ") if deps.is_a? Array

          "Dependency chain for #{relative file}:\n  #{deps}"
        }.join("\n\n") + "\n"

        @log.info result

        result
      end
    end
  end
end
