#!/usr/bin/env ruby
require 'tempfile'
require File.expand_path(File.join(File.dirname(__FILE__), 'compressor')) unless defined?(Juicer::Minifyer::Compressor)

module Juicer
  module Minifyer

    # Provides an interface to the YUI compressor library using
    # Juicer::Minify::Compressor. The YUI compressor library is implemented
    # using Java, and as such Java is required when running this code. Also, the
    # YUI jar file has to be provided.
    #
    # The YUI Compressor is invoked using the java binary and the YUI Compressor
    # jar file.
    #
    # Providing the Jar file (usually yuicompressor-x.y.z.jar) can be done in
    # several ways. The following directories are searched (in preferred order)
    #
    #  1. The directory specified by the option :bin_path
    #  2. The directory specified by the environment variable $YUIC_HOME, if set
    #  3. Current working directory
    #
    # For more information on how the Jar is located, see
    # +Juicer::Minify::YuiCompressor.locate_jar+
    #
    # Author::    Christian Johansen (christian@cjohansen.no)
    # Copyright:: Copyright (c) 2008-2009 Christian Johansen
    # License::   MIT
    #
    # = Usage example =
    # yuic = Juicer::Minifyer::YuiCompressor.new({ :bin_path => '/home/user/java/yui/' })
    # yuic.compress('lib.js', 'lib.compressed.js')
    #
    class YuiCompressor < Compressor
      def initialize(options = {})
        super
        @jar = nil
        @command = nil
      end

      # Compresses a file using the YUI Compressor. Note that the :bin_path
      # option needs to be set in order for YuiCompressor to find and use the
      # YUI jar file. Please refer to the class documentation for how to set
      # this.
      #
      # file = The file to compress
      # output = A file or stream to save the results to. If not provided the
      #          original file will be overwritten
      # type = Either :js or :css. If this parameter is not provided, the type
      #        is guessed from the suffix on the input file name
      def save(file, output = nil, type = nil)
        type = type.nil? ? file.split('.')[-1].to_sym : type
        cmd = @command = @command.nil? || @opt_set || type != @type ? command(type) : @command

        output ||= file
        use_tmp = !output.is_a?(String)
        output = File.join(Dir::tmpdir, File.basename(file) + '.min.tmp.' + type.to_s) if use_tmp
        FileUtils.mkdir_p(File.dirname(output))

        cmd += ' -o "' + output + '" "' + file + '"'
        compressor = IO.popen(cmd, 'r')
        result = compressor.gets

        if use_tmp                            # If no output file is provided, YUI compressor will
          output.puts IO.read(output)         # compress to a temp file. This file should be cleared
          File.delete(output)                 # out after we fetch its contents.
        end
      end

      chain_method :save

     private
      # Constructs the command to use
      def command(type)
        @opt_set = false
        @type = type
        @jar = locate_jar unless @jar
        raise 'Unable to locate YUI Compressor Jar' if @jar.nil?
        "#{@options[:java]} -jar #{@jar} --type #{@type} #{options(:bin_path, :java)}"
      end

      # Returns a map of options accepted by YUI Compressor, currently:
      #
      # :charset
      # :line_break
      # :no_munge (JavaScript only)
      # :preserve_semi
      # :preserve_strings
      #
      # In addition, some class level options may be set:
      # :bin_path (defaults to Dir.cwd)
      # :java     (Java command, defaults to 'java')
      def default_options
        { :charset => nil, :line_break => nil, :no_munge => nil,
          :preserve_semi => nil, :preserve_strings => nil,
          :bin_path => nil, :java => 'java' }
      end

      # Locates the Jar file by searching directories.
      # The following directories are searched (in preferred order)
      #
      #  1. The directory specified by the option :bin_path
      #  2. The directory specified by the environment variable $YUIC_HOME, if set
      #  3. Current working directory
      #
      # If any of these folders contain one or more files named like
      # yuicompressor.jar or yuicompressor-x.y.z.jar the method will pick the
      # last file in the list returned by +Dir.glob("#{dir}/yuicompressor*.jar").sort+
      # This means that higher version numbers will be preferred with the default
      # naming for the YUI Compressor Jars
      def locate_jar
        paths = @options[:bin_path].nil? ? [] : [@options[:bin_path]]
        jar = nil

        if ENV.key?('YUIC_HOME') && File.exist?(ENV['YUIC_HOME'])
          paths << ENV['YUIC_HOME']
        end

        (paths << Dir.pwd).each do |path|
          files = Dir.glob(File.join(path, 'yuicompressor*.jar'))
          jar = files.sort.last unless files.empty?
          break unless jar.nil?
        end

        jar.nil? ? nil : File.expand_path(jar)
      end
    end

    # Run YUI Compressor with command line interface semantics
    #
    class Cli
      def self.run(args)
        if args.length != 2
          puts 'Usage: yui_compressor.rb input ouput'
        else
          yc = Juicer::Minify::YuiCompressor.new
          yc.compress(args.shift, args.shift)
        end
      end
    end
  end
end

Juicer::Minifyer::Compressor::Cli.run($*) if $0 == __FILE__
