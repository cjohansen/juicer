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
      def initialize(log = nil)
        super('merge', false, true)
        @types = { :js => Juicer::Merger::JavaScriptMerger,
                   :css => Juicer::Merger::StylesheetMerger }
        @output = nil
        @force = false
        @type = nil
        @minifyer = "yui_compressor"
        @opts = {}
        @arguments = nil
        @log = log || Logger.new(STDOUT)

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
          opt.on("-o", "--output file", "Output filename") { |filename| @output = filename }
          opt.on("-p", "--path path", "Path to compressor binary") { |path| @opts[:bin_path] = path }
          opt.on("-m", "--minifyer name", "Which minifer to use. Currently only supports yui_compressor") { |name| @minifyer = name }
          opt.on("-f", "--force", "Force overwrite of target file") { @force = true }
          opt.on("-a", "--arguments arguments", "Arguments to minifyer, escape with quotes") { |arguments| @arguments = arguments }
          opt.on("-t", "--type type", "Juicer can only guess type when files have .css or .js extensions. Specify js or\n" +
                           (" " * 37) + "css with this option in cases where files have other extensions.") { |type| @type = type }
        end
      end

      # Execute command
      #
      def execute(args)
        if (files = files(args)).length == 0
          @log.fatal "Please provide atleast one input file"
          raise SystemExit.new("Please provide atleast one input file")
        end

        min = minifyer()
        output = output(files.first)

        if File.exists?(output) && !@force
          msg = "Unable to continue, #{output} exists. Run again with --force to overwrite"
          @log.fatal msg
          raise SystemExit.new(msg)
        end

        merger = merger(output).new(files)
        merger.set_next(min) if min
        merger.save(output)

        # Print report
        @log.info "Produced #{relative output} from"
        merger.files.each { |file| @log.info "  #{relative file}" }
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
          @log.debug "Using #{@minifyer.camel_case} for minification"

          return compressor
        rescue NameError
          @log.fatal "No such minifyer '#{@minifyer}', aborting"
          raise SystemExit.new("No such minifyer '#{@minifyer}', aborting")
        rescue FileNotFoundError => e
          @log.fatal e.message
          @log.fatal "Try installing with; juicer install #{@minifyer.underscore}"
          raise SystemExit.new(e.message)
        rescue Exception => e
          @log.fatal e.message
          raise SystemExit.new(e.message)
        end

        nil
      end

      #
      # Resolve and load merger
      #
      def merger(output = "")
        type = @type || output.split(/\.([^\.]*)$/)[1]
        type = type.to_sym if type

        if !@types.include?(type)
          @log.error "Unknown type '#{type}', defaulting to 'js'"
          type = :js
        end

        @types[type]
      end

      #
      # Generate output file name. Optional argument is a filename to base the new
      # name on. It will prepend the original suffix with ".min"
      #
      def output(file = "#{Time.now.to_i}.tmp")
        @output || file.sub(/\.([^\.]+)$/, '.min.\1')
      end
    end
  end
end
