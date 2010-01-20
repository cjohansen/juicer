require "juicer"
require "juicer/install/base"
require "zip/zip"

module Juicer
  module Install
    #
    # Install and uninstall routines for the Google Closure Compiler.
    # Installation downloads the Closure Compiler distribution, unzips it and
    # storesthe jar file on disk along with the README.
    #
    class ClosureCompilerInstaller < Base
      def initialize(install_dir = Juicer.home)
        super(install_dir)
        @latest = nil
        @website = "http://code.google.com/p/closure-compiler/downloads/list"
        @download_link = "http://closure-compiler.googlecode.com/files/compiler-%s.zip"
      end

      #
      # Install the Closure Compiler. Downloads the distribution and keeps the jar
      # file inside PATH/closure_compiler/bin and the README in
      # PATH/closere_compiler/yyyymmdd/ where yyyymmdd is the version, most recent if
      # not specified otherwise.
      #
      # Path defaults to environment variable $JUICER_HOME or default Juicer
      # home
      #
      def install(version = nil)
        version = super(version)
        base = "closure-compiler-#{version}"
        filename = download(@download_link % version)
        target = File.join(@install_dir, path)

        Zip::ZipFile.open(filename) do |file|
          file.extract("README", File.join(target, version, "README"))
          file.extract("compiler.jar", File.join(target, "bin", "#{base}.jar"))
        end
      end

      #
      # Uninstalls the given version of Closure Compiler. If no location is
      # provided the environment variable $JUICER_HOME or Juicers default home
      # directory is used.
      #
      # If no version is provided the most recent version is assumed.
      #
      # If there are no more files left in INSTALLATION_PATH/closure_compiler, the
      # whole directory is removed.
      #
      def uninstall(version = nil)
        super(version) do |dir, version|
          File.delete(File.join(dir, "bin/closure-compiler-#{version}.jar"))
        end
      end

      #
      # Check which version is the most recent
      #
      def latest
        return @latest if @latest
        webpage = Nokogiri::HTML(open(@website))
        @latest = (webpage / "//table[@id='resultstable']//td/a[contains(@href, 'compiler')]").map{|link|
          link.get_attribute('href')[/\d{8}/].to_i
        }.sort.last.to_s
      end
    end
  end
end
