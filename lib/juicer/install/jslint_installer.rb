require "juicer"
require "juicer/install/base"
require "zip/zip"

module Juicer
  module Install
    #
    # Install and uninstall routines for the JSLint library by Douglas Crockford.
    # Installation downloads the jslintfull.js and rhino.js files and stores
    # them in the Juicer installation directory.
    #
    class JSLintInstaller < Base
      attr_reader :latest

      def initialize(install_dir = Juicer.home)
        super(install_dir)
        @latest = "1.0"
        @website = "http://www.jslint.com/"
        @path = "lib/jslint"
        @name = "JsLint"
        dependency :rhino
      end

      #
      # Install JSLint. Downloads the two js files and stores them in the
      # installation directory.
      #
      def install(version = nil)
        version = super(version)
        #filename = download(File.join(@website, "rhino/jslint.js"))

        # TEMP fix, Crockford took down the Rhino version, bundle for now
        filename = File.join(File.expand_path(File.dirname(__FILE__)), "../../jslint/jslint-rhino.js")
        FileUtils.copy(filename, File.join(@install_dir, path, "bin", "jslint-#{version}.js"))
      end

      #
      # Uninstalls JSLint
      #
      def uninstall(version = nil)
        super(version) do |dir, version|
          File.delete(File.join(dir, "bin", "jslint-#{version}.js"))
        end
      end
    end

    #
    # This class makes it possible to do Juicer.install("jslint") instead of
    # Juicer.install("j_s_lint"). Sugar, sugar...
    #
    class JslintInstaller < JSLintInstaller
    end
  end
end
