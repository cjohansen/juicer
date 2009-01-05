require File.expand_path(File.join(File.dirname(__FILE__), "base"))

module Juicer
  module Install
    #
    # Install and uninstall routines for the YUI Compressor.
    # Installation downloads the YUI Compressor distribution, unzips it and
    # storesthe jar file on disk along with the license.
    #
    class YuiCompressorInstaller < Base
      WEBSITE = "http://www.julienlecomte.net/yuicompressor/"
      @@latest = nil

      #
      # Install the Yui Compressor. Downloads the distribution and keeps the jar
      # file inside PATH/yui_compressor/bin and the README and CHANGELOG in
      # PATH/yui_compressor/x.y.z/ where x.y.z is the version, most recent if
      # not specified otherwise.
      #
      # Path defaults to environment variable $JUICER_HOME or default Juicer
      # home
      #
      def self.install(install_dir = nil, version = nil)
        version = super(install_dir, version)
        filename = "yuicompressor-#{version}.zip"

        # Download file
        puts "Downloading #{WEBSITE + filename}"
        webpage = open(WEBSITE + filename)
        download = open(File.join(install_dir, filename), "wb")
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
      def self.uninstall(install_dir = nil, version = nil)
        super(install_dir, version) do |dir, version|
          File.delete(File.join(dir, "bin/yuicompressor-#{version}.jar"))
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
