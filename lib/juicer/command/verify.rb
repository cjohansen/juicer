require "juicer/command/util"
require "rubygems"
require "cmdparse"
require "pathname"

module Juicer
  module Command
    # Verifies problem-free-ness of source code (JavaScript and CSS)
    #
    class Verify < CmdParse::Command
      include Juicer::Command::Util

      # Initializes command
      #
      def initialize(log = nil)
        super('verify', false, true)
        @log = log || Logger.new($STDIO)
        self.short_desc = "Verifies that the given JavaScript/CSS file is problem free"
        self.description = <<-EOF
Uses JsLint (http://www.jslint.com) to check that code adheres to good coding
practices to avoid potential bugs, and protect against introducing bugs by
minifying.
        EOF
      end

      # Execute command
      #
      def execute(args)
        # Need atleast one file
        raise ArgumentError.new('Please provide atleast one input file/pattern') if args.length == 0
        Juicer::Command::Verify.check_all(files(args), @log)
      end

      def self.check_all(files, log = nil)
        log ||= Logger.new($stdio)
        jslint = Juicer::JsLint.new(:bin_path => Juicer.home)
        problems = false

        # Check that JsLint is installed
        raise FileNotFoundError.new("Missing 3rd party library JsLint, install with\njuicer install jslint") if jslint.locate_lib.nil?

        # Verify all files
        files.each do |file|
          log.info "Verifying #{file} with JsLint"
          report = jslint.check(file)

          if report.ok?
            log.info "  OK!"
          else
            problems = true
            log.warn "  Problems detected"
            log.warn "  #{report.errors.join("\n").gsub(/\n/, "\n  ")}\n"
          end
        end

        !problems
      end
    end
  end
end
