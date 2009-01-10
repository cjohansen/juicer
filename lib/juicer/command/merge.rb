require File.join(File.dirname(__FILE__), "util")
require "rubygems"
require "cmdparse"
require "pathname"

module Juicer
  module Command
    # The compress command combines and minifies CSS and JavaScript files
    #
    class Merge < CmdParse::Command
      include Juicer::Command::Util

      # Initializes compress command
      #
      def initialize
        super('merge', false, true)
        @types = { :js => Juicer::Merger::JavaScriptMerger,
                   :css => Juicer::Merger::StylesheetMerger }
        @output = nil
        @force = false
        @minifyer = "yui_compressor"
        @opts = {}
        @arguments = nil
        self.short_desc = "Combines and minifies CSS and JavaScript files"
        self.description = <<-EOF
Each file provided as input will be checked for dependencies to other files,
and those files will be added to the final output

For CSS files the dependency checking is done through regular @import
statements.

For JavaScript files you can tell Juicer about dependencies through special
comment switches. These should appear inside a multi-line comment, specifically
inside the first multi-line comment. The switch is @depend or @depends, your
choice.

The -m --minifyer switch can be used to select which minifyer to use. Currently
only YUI Compressor is supported, ie -m yui_compressor (default). When using
the YUI Compressor the path should be the path to where the jar file is found.
        EOF

        self.options = CmdParse::OptionParserWrapper.new do |opt|
          opt.on('-o', '--output [OUTPUT]', 'Output filename') { |filename| @output = filename }
          opt.on('-p', '--path [PATH]', 'Path to compressor binary') { |path| @opts[:bin_path] = path }
          opt.on('-m', '--minifyer [MINIFYER]', 'Which minifer to use. Currently only supports YUI Compressor') { |name| @minifyer = name }
          opt.on('-f', '--force', 'Force overwrite of target file') { @force = true }
          opt.on('-a', '--arguments [ARGUMENTS]', 'Arguments to minifyer, escape with quotes') { |arguments| @arguments = arguments }
        end
      end

      # Execute command
      #
      def execute(args)
        if args.length == 0
          raise OptionParser::ParseError.new('Please provide atleast one input file')
        end

        args = files(args)
        min = minifyer()

        # If no file name is provided, use name of first input with .min
        # prepended to suffix
        @output = @output || args[0].sub(/\.([^\.]+)$/, '.' + (min ? 'min' : 'merge') + '.\1')

        if File.exists?(@output) && !@force
          puts "Unable to continue, #{@output} exists. Run again with --force to overwrite"
          exit
        end

        merger = @types[@output.split(/\.([^\.]*)$/)[1].to_sym].new(args)
        merger.set_next(min) if min
        merger.save(@output)

        # Print report
        puts "Produced #{relative @output} from"
        merger.files.each { |file| puts "  #{relative file}" }
      end

     private
      #
      # Resolve and load minifyer
      #
      def minifyer
        return nil if @minifyer.nil? || @minifyer == "" || @minifyer.downcase == "none"

        begin
          @opts[:bin_path] = File.join(Juicer.home, @minifyer, "bin") unless @opts[:bin_path]
          compressor = @minifyer.classify(Juicer::Minifyer).new(@opts)
          compressor.set_opts(@arguments) if @arguments
        rescue NameError
          puts "No such minifyer '#{@minifyer}', aborting"
          exit
        rescue Exception => e
          puts e.message
          exit
        end

        compressor
      end
    end
  end
end
