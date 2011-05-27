require 'nokogiri'
require 'open-uri'
require 'fileutils'
require "juicer"

module Juicer
  module Install
    #
    # Installer skeleton. Provides basic functionality like figuring out where
    # to install, create base directories, remove unneeded directories and more
    # housekeeping.
    #
    class Base
      attr_reader :install_dir

      #
      # Create new installer
      #
      def initialize(install_dir = Juicer.home)
        @install_dir = install_dir
        @path = nil
        @bin_path = nil
        @name = nil
        @dependencies = {}
      end

      #
      # Returns the latest available version number. Must be implemented in
      # subclasses. Raises an exception when called directly.
      #
      def latest
        raise NotImplementedError.new("Implement in subclasses")
      end

      # Returns the path relative to installation path this installer will
      # install to
      def path
        return @path if @path
        @path = "lib/" + self.class.to_s.split("::").pop.sub(/Installer$/, "").underscore
      end

      # Returns the path to search for binaries from
      #
      def bin_path
        return @bin_path if @bin_path
        @bin_path = File.join(path, "bin")
      end

      #
      # Returns name of component. Default implementation returns class name
      # with "Installer" removed
      #
      def name
        return @name if @name
        @name = File.basename(path).split("_").inject("") { |str, word| (str + " #{word.capitalize}").strip }
      end

      #
      # Checks if the component is currently installed.
      #
      # If no version is provided the most recent version is assumed.
      #
      def installed?(version = nil)
        installed = File.exists?(File.join(@install_dir, path, "#{version || latest}"))
        deps = @dependencies.length == 0 || dependencies.all? { |d, v| d.installed?(v) }
        installed && deps
      end

      #
      # Install the component. Creates basic directory structure.
      #
      def install(version = nil)
        raise "#{name} #{version} is already installed in #{File.join(@install_dir, path)}" if installed?(version)
        version ||= latest
        log "Installing #{name} #{version} in #{File.join(@install_dir, path)}"

        if @dependencies.length > 0
          log "Installing dependencies"
          dependencies { |dependency, ver| dependency.install(ver) unless dependency.installed?(ver) }
        end

        # Create directories
        FileUtils.mkdir_p(File.join(@install_dir, path, "bin"))
        FileUtils.mkdir_p(File.join(@install_dir, path, version))

        # Return resolved version for subclass to use
        version
      end

      #
      # Uninstalls the given version of the component.
      #
      # If no version is provided the most recent version is assumed.
      #
      # If there are no more files left in INSTALLATION_PATH/<path>, the
      # whole directory is removed.
      #
      # This method takes a block and can be used from subclasses like so:
      #
      #   def self.uninstall(install_dir = nil, version = nil)
      #     super do |home_dir, version|
      #       # Custom uninstall logic
      #     end
      #   end
      #
      #
      def uninstall(version = nil)
        version ||= self.latest
        install_dir = File.join(@install_dir, path, version)
        raise "#{name} #{version} is not installed" if !File.exists?(install_dir)

        FileUtils.rm_rf(install_dir)

        yield(File.join(@install_dir, path), version) if block_given?

        files = Dir.glob(File.join(@install_dir, path, "**", "*")).find_all { |f| File.file?(f) }
        FileUtils.rm_rf(File.join(@install_dir, path)) if files.length == 0
      end

      #
      # Download a file to Juicer temporary directory. The file will be kept
      # until #purge is called to wipe it. If the installer receives a request
      # to download the same file again, the disk cache will be used unless the
      # force argument is true (default false)
      #
      def download(url, force = false)
        filename = File.join(@install_dir, "download", path.sub("lib/", ""), File.basename(url).split("?").first)
        return filename if File.exists?(filename) && !force
        FileUtils.mkdir_p(File.dirname(filename))
        File.delete(filename) if File.exists?(filename) && force

        log "Downloading #{url}"
        File.open(filename, "wb") do |file|
          webpage = open(url)
          file.write(webpage.read)
          webpage.close
        end

        filename
      end

      #
      # Display a message to the user through Juicer::LOGGER
      #
      def log(str)
        Juicer::LOGGER.info str
      end

      #
      # Add a dependency. Dependency should be a Juicer::Install::Base installer
      # class (not instance) OR a symbol/string like :rhino/"rhino" (which will
      # be expanded unto Juicer::Install::RhinoInstaller). Version is optional
      # and defaults to latest and greatest.
      #
      def dependency(dependency, version = nil)
        dependency = Juicer::Install.get(dependency) if [String, Symbol].include?(dependency.class)

        @dependencies[dependency.to_s + (version || "")] = [dependency, version]
      end

      #
      # Yields depencies one at a time: class and version and returns an array
      # of arrays: [dependency, version] where dependency is an instance and
      # version a string.
      #
      def dependencies(&block)
        @dependencies.collect do |name, dependency|
          version = dependency[1]
          dependency = dependency[0].new(@install_dir)
          block.call(dependency, version) if block
          [dependency, version]
        end
      end
    end

    #
    # Returns the installer. Accepts installer classes (which are returned
    # directly), strings or symbols. Strings and symbols may be on the form
    # :my_module which is expanded to Juicer::Install::MyModuleInstaller
    #
    def self.get(nameOrClass)
      return nameOrClass if nameOrClass.is_a? Class
      (nameOrClass.to_s + "_installer").classify(Juicer::Install)
    end
  end
end
