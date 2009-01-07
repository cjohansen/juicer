require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'fileutils'
require File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. juicer])) unless defined?(Juicer)

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
        @name = nil
      end

      #
      # Returns the latest available version number. Must be implemented in
      # subclasses. Raises an exception when called directly.
      #
      def latest
        raise NotImplementedError.new "Implement in subclasses"
      end

      # Returns the path relative to installation path this installer will
      # install to
      def path
        return @path if @path
        @path = "lib/" + self.class.to_s.split("::").pop.sub(/Installer$/, "").underscore
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
        File.exists?(File.join(@install_dir, path, "#{version || latest}"))
      end

      #
      # Install the component. Creates basic directory structure.
      #
      def install(version = nil)
        version ||= latest
        log "Installing #{name} #{version} in #{File.join(@install_dir, path)}"

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
        filename = File.join(@install_dir, "download", path.sub("lib/", ""), File.basename(url))
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
      # Display a message to the user if the global variable $verbose is true.
      # TODO: Remove
      #
      def log(str)
        #puts str if defined? $verbose && $verbose
      end
    end
  end
end
