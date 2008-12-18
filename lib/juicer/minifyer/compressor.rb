#!/usr/bin/env ruby
require 'logger'

module Juicer
  module Minifyer

    # Juicer::Minifyer::Compressor defines an API for compressing CSS,
    # JavaScript and others using either a third party compressor library, or by
    # implementing compression routines in Ruby.
    #
    # The Compressor class itself is not able to do anything useful other than
    # serving as a framework for concrete compressors to implement.
    #
    # Author::    Christian Johansen (christian@cjohansen.no)
    # Copyright:: Copyright (c) 2008 Christian Johansen
    # License::   MIT
    #
    class Compressor
      # Initialize compressor with path to run from and options
      # options = Hash of options, optional
      def initialize(options = {})
        @options = default_options.merge(options)
        @opt_set = false
      end

      # Perform compression, should be implemented in subclasses
      # file = The file to compress
      # output = Output file, if nil return the compressed contents as a string
      # type = The type of file, js or css
      def compress(file, output = nil, type = :js)
        msg = "Unable to call compress on abstract class Compressor"
        raise NotImplementedError.new(msg)
      end

      # Return the value of a given option
      # opt = The option to return value for
      def get_opt(opt)
        @options[opt] || nil
      end

      # Set an option. Important: you can only set options that are predefined by the
      # implementing class
      # opt = The option to set
      # value = The value of the option
      def set_opt(opt, value)
        if @options.key?(opt)
          @options[opt] = value
          @opt_set = true
        else
          msg = 'Illegal option, specify one of: ' + @options.keys.join(', ')
          raise ArgumentError.new(msg)
        end
      end

      # Allows for options to be set and read directly on the object as though they were
      # standard attributes. compressor.verbose translates to
      # compressor.get_opt('verbose') and compressor.verbose = true to
      # compressor.set_opt('verbose', true)
      def method_missing(m, *params)
        if @options.key?(m)
          return get_opt(m)
        elsif @options.key?(m.to_s.split('=')[0].to_sym)
          return set_opt(m.to_s.split('=')[0].to_sym, params[0])
        end

        super
      end

     private
      # May be overridden in subclasses. Provides default options
      def default_options
        {}
      end
    end
  end
end
