require "juicer/chainable"

module Juicer

  # Defines an abstract implementation of a binary that needs to be "shelled
  # out" to be run. Provides a starting point when wrapping and API around a
  # shell binary.
  #
  # The module requires the including class to define the default_options
  # method. It should return a hash of options where options are keys and
  # default values are the values. Only options defined in this hash will be
  # allowed to set on the binary.
  #
  module Binary
    # Initialize binary with options
    # options = Hash of options, optional
    #
    def initialize(binary, options = {})
      @options = self.respond_to?(:default_options) ? default_options.merge(options) : options
      @opt_set = false
      @command = nil
      @binary = binary
      @path = []
    end

    def path
      @path
    end

    # Run command
    #
    def execute(params = nil)
      cmd = IO.popen("#{self.command} #{params}", "r")
      results = cmd.gets(nil)
      cmd.close
      results
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
    # parameters are set, non-existent arguments raise an ArgumentError
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

    # Constructs the command to use
    #
    def command
      return @command if !@opt_set && @command
      @opt_set = false
      @command = "#{@binary} #{options}"
    end

    # Locate the binary to execute. The binary is searched for in the
    # following places:
    #
    # 1) The paths specified through my_binary.path << "/usr/bin"
    # 2) The path specified by the given environment variable
    # 3) Current working directory
    #
    # The name of the binary may be a glob pattern, resulting in +locate+
    # returning an array of matches. This is useful in cases where the path
    # is expected to store several versions oof a binary in the same directory,
    # like /usr/bin/ruby /usr/bin/ruby1.8 /usr/bin/ruby1.9
    #
    # +locate+ always returns an array, or nil if no binaries where found.
    # The result is always all files matching the given pattern in *one* of
    # the specified paths - ie the first path where the pattern matches
    # something.
    #
    def locate(bin_glob, env = nil)
      path << ENV[env] if env && ENV.key?(env) && File.exist?(ENV[env])
      
      (path << Dir.pwd).each do |path|
        files = Dir.glob(File.expand_path(File.join(path, bin_glob)))
        return files unless files.empty?
      end

      nil
    end

    # Allows for options to be set and read directly on the object as though they were
    # standard attributes. compressor.verbose translates to
    # compressor.get_opt('verbose') and compressor.verbose = true to
    # compressor.set_opt('verbose', true)
    def method_missing(m, *args)
      if @options.key?(m)
        # Only hit method_missing once per option
        self.class.send(:define_method, m) do       # def verbose
          get_opt(m)                                #   get_opt(:verbose)
        end                                         # end

        return get_opt(m)
      end

      return super unless m.to_s =~ /=$/

      opt = m.to_s.sub(/=$/, "").to_sym

      if @options.key?(opt)
        # Only hit method_missing once per option
        self.class.send(:define_method, m) do      # def verbose=(val)
          set_opt(opt, args[0])                    #   set_opt(:verbose, val)
        end                                        # end

        return set_opt(opt, args[0])
      end

      super
    end
  end
end
