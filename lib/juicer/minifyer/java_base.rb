#!/usr/bin/env ruby
require 'tempfile'
require 'juicer/binary'

module Juicer
  module Minifyer

    # Provides an interface to Java based compressor libraries using
    # Juicer::Shell::Binary.
    #
    # The compressor is invoked using the java binary and the compressor jar
    # file.
    #
    # Providing the Jar file can be done in several ways. The following
    # directories are searched (in preferred order)
    #
    #  1. The directory specified by the option :bin_path
    #  2. The directory specified by the environment variable, if set
    #  3. Current working directory
    #
    # Name of environment variable is decided by including classes self.env_name
    # constant.
    #
    # For more information on how the Jar is located, see
    # +Juicer::Minify::JavaMinifyer.locate_jar+
    #
    # Author::    Christian Johansen (christian@cjohansen.no)
    # Copyright:: Copyright (c) 2008-2009 Christian Johansen
    # License::   MIT
    #
    module JavaBase
      include Juicer::Binary

      def initialize(options = {})
        bin = options.delete(:java) || "java"
        bin_path = options.delete(:bin_path) || nil
        @jar = nil
        @jar_args = nil

        super(bin, options)
        path << bin_path if bin_path
      end

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

      # Locates the Jar file by searching directories.
      # The following directories are searched (in preferred order)
      #
      #  1. The directory specified by the option :bin_path
      #  2. The directory specified by the environment variable, if set
      #  3. Current working directory
      #
      # If any of these folders contain one or more files named like
      # [self.class.bin_base_name].jar or [self.class.bin_base_name]-x.y.z.jar
      # the method willpick the last file in the list returned by
      # +Dir.glob("#{dir}/[self.class.bin_base_name]*.jar").sort. This means that
      # higher version numbers will be preferred with the default naming for the
      # jars
      #
      def locate_jar
        files = locate("#{self.class.bin_base_name}*.jar", self.class.env_name)
        !files || files.empty? ? nil : files.sort.last
      end
    end
  end
end
