require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'fileutils'
require File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "juicer"))

module Juicer
  module Install
    #
    # Install and uninstall routines for the YUI Compressor.
    # Installation downloads the YUI Compressor distribution, unzips it and
    # storesthe jar file on disk along with the license.
    #
    class YuiCompressorInstaller
      WEBSITE = "http://www.julienlecomte.net/yuicompressor/"
      @@latest = nil

      #
      # Checks if the Yui Compressor is currently installed in the specific
      # location. If no location is provided the environment variable
      # $JUICER_HOME or Juicers default home directory is used.
      #
      # If no version is provided the most recent version is assumed.
      #
      def self.installed?(path = nil, version = nil)
        path ||= Juicer::HOME
        File.exists?(File.join(path, "yui_compressor/#{version || self.latest}"))
      end

      #
      # Install the Yui Compressor. Downloads the distribution and keeps the jar
      # file inside PATH/yui_compressor/bin and the README and CHANGELOG in
      # PATH/yui_compressor/x.y.z/ where x.y.z is the version, most recent if
      # not specified otherwise.
      #
      # Path defaults to environment variable $JUICER_HOME or default Juicer
      # home
      #
      def self.install(path = nil, version = nil)
        path ||= Juicer::HOME
        version ||= self.latest

        puts "Installing YUI Compressor #{version} in #{File.join(path, "yui_compressor")}"

        # Create directories
        FileUtils.mkdir_p(File.join(path, "yui_compressor", "bin"))
        FileUtils.mkdir_p(File.join(path, "yui_compressor", version))

        # Open webpage
        filename = "yuicompressor-#{version}.zip"
        webpage = open(WEBSITE + filename)

        # Download file
        puts "Downloading #{WEBSITE + filename}"
        download = open(File.join(path, filename), "wb")
        download.write(webpage.read)
        download.close
        webpage.close


      end

      #
      # Uninstalls the given version of YUI Compressor. If no location is
      # provided the environment variable $JUICER_HOME or Juicers default home
      # directory is used.
      #
      # If no version is provided the most recent version is assumed.
      #
      # If there are no more files left in INSTALLATION_PATH/yui_compressor, the
      # whole directory is removed.
      #
      def self.uninstall(path = nil, version = nil)
        path ||= Juicer::HOME
        version ||= self.latest
        path = File.join(path, "yui_compressor", version)
        raise "YUI Compressor #{version} is not installed" if !File.exists?(path)

        File.delete(path)
        File.delete(File.join(path, "yui_compressor/bin/yuicompressor-#{version}.jar"))

        files = Dir.glob(File.join(path, "yui_compressor", "**", "*")).find_all { |f| File.file?(f) }

        if files.length == 0
          FileUtils.rm_rf(File.join(path, "yui_compressor"))
        end
      end

      #
      # Check which version is the most recent
      #
      def self.latest
        return @@latest if @@latest
        webpage = Hpricot(open(WEBSITE))
        @@latest = (webpage / "#downloadbutton a")[0].get_attribute("href").match(/(\d\.\d\.\d)/)[1]
      end
    end
  end
end
