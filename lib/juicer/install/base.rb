require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'fileutils'
require File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. lib juicer])) unless defined?(Juicer)

module Juicer
  module Install
    #
    # Installer skeleton. Provides basic functionality like figuring out where
    # to install, create base directories, remove unneeded directories and more
    # housekeeping.
    #
    class Base
      @@path = nil

      #
      # Returns the path relative to installation path this installer will
      # install to
      #
      def self.path
        return @@path if @@path
        @@path = "lib/" + self.to_s.split("::").pop.sub(/Installer$/, "").underscore
      end

      #
      # Returns the latest available version number. Must be implemented in
      # subclasses. Raises an exception when called directly.
      #
      def self.latest
        raise NotImplementedError.new "Implement in subclasses"
      end

      #
      # Returns name of component. Default implementation returns class name
      # with "Installer" removed
      #
      def self.name
        self.path.split("_").inject("") { |str, word| (str + " #{word.capitalize}").strip }
      end

      #
      # Checks if the component is currently installed in the specific
      # location. If no location is provided the environment variable
      # $JUICER_HOME or Juicers default home directory is used.
      #
      # If no version is provided the most recent version is assumed.
      #
      def self.installed?(install_dir = nil, version = nil)
        install_dir ||= Juicer.home
        File.exists?(File.join(install_dir, self.path, "#{version || self.latest}"))
      end

      #
      # Install the component. Creates basic directory structure.
      #
      def self.install(install_dir = nil, version = nil)
        install_dir ||= Juicer.home
        version ||= self.latest

        puts "Installing #{name} #{version} in #{File.join(install_dir, self.path)}"

        # Create directories
        FileUtils.mkdir_p(File.join(install_dir, self.path, "bin"))
        FileUtils.mkdir_p(File.join(install_dir, self.path, version))

        # Return resolved version for subclass to use
        version
      end

      #
      # Uninstalls the given version of the component. If no location is
      # provided the environment variable $JUICER_HOME or Juicers default home
      # directory is used.
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
      def self.uninstall(install_dir = nil, version = nil)
        install_dir ||= Juicer.home
        version ||= self.latest
        install_dir = File.join(install_dir, self.path, version)
        raise "#{name} #{version} is not installed" if !File.exists?(install_dir)

        File.delete(install_dir)

        yield(File.join(install_dir, self.path), version)

        files = Dir.glob(File.join(install_dir, self.path, "**", "*")).find_all { |f| File.file?(f) }
        FileUtils.rm_rf(File.join(install_dir, self.path)) if files.length == 0
      end

      #
      # Download a file to Juicer temporary directory. The file will be kept
      # until #purge is called to wipe it. If the installer receives a request
      # to download the same file again, the disk cache will be used unless the
      # force argument is true (default false)
      #
      def self.download(file, force = false)

      end
    end
  end
end
