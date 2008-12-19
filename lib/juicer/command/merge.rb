require 'rubygems'
require 'cmdparse'
require 'tempfile'

module Juicer
  module Command
    # The compress command combines and minifies CSS and JavaScript files
    #
    class Merge < CmdParse::Command
      # Initializes compress command
      #
      def initialize
        super('merge', false, true)
        @output = nil
        @opts = {}
        self.short_desc = "Combines and minifies CSS and JavaScript files"
        self.description = <<-EOF
Combines and minifies CSS and JavaScript files. Each file provided as input will
be checked for dependencies to other files, and those files will be added to
the final output

For CSS files the dependency checking is done through @import statements. For
JavaScript files you can tell Juicer about dependencies through special comment
switches. These should appear inside a multi-line comment, specifically inside
the first multi-line comment. The switch is @depend or @depends, your choice.

Given a file test.js that looks like:

/**
 * Test JavaScript
 *
 * @depend lib.js
 */
var Test = {
    version: "1.0"
};

and the file lib.js:

/**
 * This is lib.js
 */
var tools = {
    dom: {}
};

Running
juicer merge test.js

Will result in the file test.min.js containing:

var Test={version:"1.0"};var tools={dom:{}}

Ready for production use. The dependencies nest indefinately.
        EOF

        self.options = CmdParse::OptionParserWrapper.new do |opt|
          opt.on( '-o', '--output [OUTPUT]', 'Output filename' ) { |filename| @output = filename }
          opt.on( '-b', '--bin-path [BIN_PATH]', 'Path to YUI Compressor jar' ) { |path| @opts[:bin_path] = path }
        end
      end

      # Execute command
      #
      def execute(args)
        if args.length == 0
          raise OptionParser::ParseError.new('Please provide atleast one input file')
        end

        @output = @output || args[0].sub(/\.([^\.]+)$/, '.min.\1')
        type = $1
        mergefile = File.join(Dir::tmpdir, Time.new.to_i.to_s + @output)

        merger = type == 'js' ? Juicer::Merger::JavaScriptFileMerger.new : Juicer::Merger::CssFileMerger.new
        merger << args
        merger.save(mergefile)
puts merger.save
puts mergefile
`cat #{mergefile}`
        compressor = Juicer::Minifyer::YuiCompressor.new(@opts)
        compressor.compress(mergefile, @output)
        File.delete(mergefile)

        puts "Produced #{@output}"
      end
    end
  end
end
