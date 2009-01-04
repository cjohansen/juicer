require File.expand_path(File.join(File.dirname(__FILE__), "..", "chainable"))

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
    # Copyright:: Copyright (c) 2008-2009 Christian Johansen
    # License::   MIT
    #
    class Compressor
      include Chainable

      # Initialize compressor with options
      # options = Hash of options, optional
      #
      def initialize(options = {})
        @options = default_options.merge(options)
        @opt_set = false
      end

      # Perform compression, should be implemented in subclasses
      # file = The file to compress
      # output = Output file or open output stream. If nil the original file is
      #          overwritten
      # type = The type of file, js or css. If not provided this is guessed from
      #        the input filename
      #
      def save(file, output = nil, type = nil)
        msg = "Unable to call compress on abstract class Compressor"
        raise NotImplementedError.new(msg)
      end

      # Return the value of a given option
      # opt = The option to return value for
      #
      def get_opt(opt)
        @options[opt] || nil
      end

      # Return options as a cli arguments string. Optionally accepts a list of
      # options to exclude from the generated string
      #
      def options(*excludes)
        excludes = excludes.flatten.collect { |exc| exc.to_sym }
        @options.inject("") do |str, opt|
          if opt[1].nil? || excludes.include?(opt[0].to_sym)
            str
          else
            val = opt[1] == true ? '' : opt[1]
            option = opt[0].to_s
            option = (option.length == 1 ? "-" : "--") + option.gsub('_', '-')
            "#{str} #{option} #{val}".strip
          end
        end
      end

      # Set an option. Important: you can only set options that are predefined by the
      # implementing class
      # opt = The option to set
      # value = The value of the option
      #
      def set_opt(opt, value)
        opt = opt.to_sym
        if @options.key?(opt)
          @options[opt] = value
          @opt_set = true
        else
          msg = "Illegal option '#{opt}', specify one of: #{@options.keys.join(', ')}"
          raise ArgumentError.new(msg)
        end
      end

      # Performs simple parsing of a string of parameters. All recognized
      # parameters are set, non-existent arguments raise an ArgumentErrror
      #
      def set_opts(options)
        options = options.split " "
        option = nil
        regex = /^--?([^=]*)(=(.*))?/

        while word = options.shift
          if word =~ regex
            if option
              set_opt option, true
            end

            if $3
              set_opt $1, $3
            else
              option = $1
            end
          else
            set_opt option, word
            option = nil
          end
        end
      end

      # Allows for options to be set and read directly on the object as though they were
      # standard attributes. compressor.verbose translates to
      # compressor.get_opt('verbose') and compressor.verbose = true to
      # compressor.set_opt('verbose', true)
      def method_missing(m, *args)
        if @options.key?(m)
          # Only hit method_missing once per option
          self.class.send(:define_method, m) do
            return get_opt(m)
          end

          return get_opt(m)
        end

        return super unless m.to_s =~ /=$/

        opt = m.to_s.sub(/=$/, "").to_sym

        if @options.key?(opt)
          # Only hit method_missing once per option
          self.class.send(:define_method, m) do
            return set_opt(opt, args[0])
          end

          return set_opt(opt, args[0])
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
