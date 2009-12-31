require "juicer/command/util"
require "cmdparse"
require "pathname"

module Juicer
  module Command
    # Installs a third party library so Juicer can use it.
    #
    class Install < CmdParse::Command
      include Juicer::Command::Util

      # Initializes command
      #
      def initialize(io = nil)
        super('install', false, true)
        @io = io || Logger.new(STDOUT)
        @version = nil
        @path = Juicer.home
        self.short_desc = "Install a third party library"
        self.description = <<-EOF
Installs a third party used by Juicer. Downloads necessary binaries and licenses
into Juicer installation directory, usually ~/.juicer
        EOF

        self.options = CmdParse::OptionParserWrapper.new do |opt|
          opt.on('-v', '--version [VERSION]', 'Specify version of library to install') { |version| @version = version }
        end
      end

      # Execute command
      #
      def execute(*args)
        args.flatten!

        if args.length == 0
          raise ArgumentError.new('Please provide a library to install')
        end

        args.each do |lib|
          installer = Juicer::Install.get(lib).new(@path)
          path = File.join(installer.install_dir, installer.path)
          version = version(installer)

          if installer.installed?(version)
            @io.info "#{installer.name} #{version} is already installed in #{path}"
            break
          end

          installer.install(version)
          @io.info "Successfully installed #{lib.camel_case} #{version} in #{path}" if installer.installed?(version)
        end
      end

      # Returns which version to install
      #
      def version(installer)
        @version ||= installer.latest
      end
    end
  end
end
