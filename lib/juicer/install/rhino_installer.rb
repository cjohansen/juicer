require "juicer"
require "juicer/install/base"
require "zip/zip"

module Juicer
  module Install
    #
    # Install and uninstall routines for the Mozilla Rhino jar.
    #
    class RhinoInstaller < Base
      def initialize(install_dir = Juicer.home)
        super(install_dir)
        @latest = nil
        @website = "http://ftp.mozilla.org/pub/mozilla.org/js/"
      end

      #
      # Install Rhino. Downloads the jar file and stores it in the installation
      # directory along with the License text.
      #
      def install(version = nil)
        version = super((version || latest).gsub(/\./, "_"))
        base = "rhino#{version}"
        filename = download(File.join(@website, "#{base}.zip"))
        target = File.join(@install_dir, path)

        Zip::ZipFile.open(filename) do |file|
          FileUtils.mkdir_p(File.join(target, version))

          begin
            file.extract("#{base.sub(/-RC\d/, "")}/LICENSE.txt", File.join(target, version, "LICENSE.txt"))
          rescue Exception
            # Fail silently, some releases don't carry the license
          end

          file.extract("#{base.sub(/-RC\d/, "")}/js.jar", File.join(target, "bin", "#{base}.jar"))
        end
      end

      #
      # Uninstalls Rhino
      #
      def uninstall(version = nil)
        super((version || latest).gsub(/\./, "_")) do |dir, version|
          base = "rhino#{version}"
          File.delete(File.join(dir, "bin/", "#{base}.jar"))
        end
      end

      def latest
        return @latest if @latest
        webpage = Nokogiri::HTML(open(@website))
        versions = (webpage / "td a").to_a.find_all { |a| a.attr("href") =~ /rhino\d_/ }
        @latest = versions.collect { |n| n.attr("href") }.sort.last.match(/rhino(\d_.*)\.zip/)[1]
      end
    end
  end
end
