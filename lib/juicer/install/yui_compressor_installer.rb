require "juicer"
require "juicer/install/base"
require "zip/zip"

module Juicer
  module Install
    #
    # Install and uninstall routines for the YUI Compressor.
    # Installation downloads the YUI Compressor distribution, unzips it and
    # storesthe jar file on disk along with the license.
    #
    class YuiCompressorInstaller < Base
      def initialize(install_dir = Juicer.home)
        super(install_dir)
        @latest = nil
        @website = "http://yuilibrary.com/downloads/"
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
      def install(version = nil)
        version = super(version)
        base = "yuicompressor-#{version}"
        filename = download(File.join(@website, "yuicompressor", "#{base}.zip"))
        target = File.join(@install_dir, path)

        Zip::ZipFile.open(filename) do |file|
          file.extract("#{base}/doc/README", File.join(target, version, "README"))
          file.extract("#{base}/doc/CHANGELOG", File.join(target, version, "CHANGELOG"))
          file.extract("#{base}/build/#{base}.jar", File.join(target, "bin", "#{base}.jar"))
        end
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
      def uninstall(version = nil)
        super(version) do |dir, version|
          File.delete(File.join(dir, "bin/yuicompressor-#{version}.jar"))
        end
      end

      #
      # Check which version is the most recent
      #
      def latest
        return @latest if @latest
        webpage = Nokogiri::HTML(open(@website))
        @latest = (webpage / "h3#yuicompressor + ul li a:last").text.match(/(\d\.\d\.\d)/)[1]
      end

    end
  end
end
