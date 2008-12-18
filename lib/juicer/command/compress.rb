require 'rubygems'
require 'cmdparse'
require 'tempfile'

module Juicer
  module Command
    # The compress command combines and minifies CSS and JavaScript files
    #
    class Compress < CmdParse::Command
      # Initializes compress command
      #
      def initialize
        super('compress', false, true)
        @output = nil
        @opts = {}
        self.short_desc = "Combines and minifies CSS and JavaScript files"

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
