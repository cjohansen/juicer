#!/usr/bin/env ruby
require 'tempfile'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'binary')) unless defined?(Juicer::Shell::Binary)

module Juicer
  module Minifyer

    # Provides an interface to the Closure compiler library using
    # Juicer::Shell::Binary. The Closure compiler library is implemented
    # using Java, and as such Java is required when running this code. Also, the
    # compiler jar file has to be provided.
    #
    # The Closure Compiler is invoked using the java binary and the compiler
    # jar file.
    #
    # Providing the Jar file (usually compiler.jar) can be done in
    # several ways. The following directories are searched (in preferred order)
    #
    #  1. The directory specified by the option :bin_path
    #  2. The directory specified by the environment variable $CLOSUREC_HOME, if set
    #  3. Current working directory
    #
    # For more information on how the Jar is located, see
    # +Juicer::Minify::ClosureCompiler.locate_jar+
    #
    # Author::    Christian Johansen (christian@cjohansen.no), Pavel Valodzka (pavel@valodzka.name)
    # Copyright:: Copyright (c) 2008-2009 Christian Johansen, (c) 2009 Pavel Valodzka
    # License::   MIT
    #
    # = Usage example =
    # yuic = Juicer::Minifyer::ClosureCompiler.new
    # yuic.java = "/usr/local/bin/java" # If 'java' is not on path
    # yuic.path << "/home/user/java/yui_compressor/"
    # yuic.save("", "")
    #
    #
    class ClosureCompiler
      include Juicer::Binary
      include Juicer::Chainable

      def initialize(options = {})
        bin = options.delete(:java) || "java"
        bin_path = options.delete(:bin_path) || nil
        @jar = nil
        @jar_args = nil

        super(bin, options)
        path << bin_path if bin_path
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

        use_tmp = unless output
                    output = file
                    file = File.join(Dir::tmpdir, File.basename(file) + '.min.tmp.' + type.to_s)
                    FileUtils.mkdir_p(File.dirname(file))
                    FileUtils.move(output, file)

                    true
                  end

        result = execute(%Q{-jar "#{locate_jar}"#{jar_args} -js_output_file "#{output}" -js "#{file}"})

        File.delete(file) if use_tmp
      end

      chain_method :save

      # Overrides set_opts called from binary class
      # This avoids sending illegal options to the java binary
      #
      def set_opts(args)
        @jar_args = " #{args}"
      end

      def jar_args
        @jar_args
      end

     private

      # Some class level options may be set:
      # :bin_path (defaults to Dir.cwd)
      # :java     (Java command, defaults to 'java')
      def default_options
        { }
      end

      # Locates the Jar file by searching directories.
      # The following directories are searched (in preferred order)
      #
      #  1. The directory specified by the option :bin_path
      #  2. The directory specified by the environment variable $CLOSUREC_HOME, if set
      #  3. Current working directory
      #
      # If any of these folders contain one or more files named like
      # *compiler*.jar the method will pick the last file in the list
      # returned by +Dir.glob("#{dir}/yuicompressor*.jar").sort+
      # This means that higher version numbers will be preferred with the default
      # naming for the Closure Compiler Jars
      def locate_jar
        files = locate("*compiler*.jar", "CLOSUREC_HOME")
        !files || files.empty? ? nil : files.sort.last
      end
    end

    # Run Closure Compiler with command line interface semantics
    #
    class Cli
      def self.run(args)
        if args.length != 2
          puts 'Usage: closure_compiler.rb input ouput'
        else
          yc = Juicer::Minify::ClosureCompiler.new
          yc.compress(args.shift, args.shift)
        end
      end
    end
  end
end

Juicer::Minifyer::Compressor::Cli.run($*) if $0 == __FILE__
