require "cmdparse"

# Command line interpreter for Juicer
#
module Juicer
  class Cli

    def initialize
      @log = Juicer::LOGGER
      @log.level = Logger::INFO
    end

    # Set up command parser and parse arguments
    #
    def parse(arguments = ARGV)
      @cmd = CmdParse::CommandParser.new(true, true)
      @cmd.program_name = "juicer"
      @cmd.program_version = Juicer.version.split(".")

      @cmd.options = CmdParse::OptionParserWrapper.new do |opt|
        opt.separator "Global options:"
        opt.on("-v", "--verbose", "Be verbose when outputting info") { |t| @log.level = Logger::DEBUG }
        opt.on("-q", "--quiet", "Only log warnings and errors") { |t| @log.level = Logger::WARN }
      end

      add_commands
      @cmd.parse(arguments)
      @log.close
    rescue SystemExit
      exit
    end

    # Run CLI
    #
    def self.run(arguments = ARGV)
      juicer = self.new
      juicer.parse(arguments)
    end

   private
    # Adds commands supported by juicer. Instantiates all classes in the
    # Juicer::Command namespace.
    #
    def add_commands
      @cmd.add_command(CmdParse::HelpCommand.new)
      @cmd.add_command(CmdParse::VersionCommand.new)

      if Juicer.const_defined?("Command")
        Juicer::Command.constants.each do |const|
          const = Juicer::Command.const_get(const)
          @cmd.add_command(const.new(@log)) if const.kind_of?(Class)
        end
      end
    end
  end
end
