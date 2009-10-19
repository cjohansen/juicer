require "test_helper"

module Juicer
  module Install
    class SomeMagicInstaller < Juicer::Install::Base
      def install(version = nil)
        version ||= "1.0.0"
        ver = super(version)
        File.open(File.join(@install_dir, path, "bin", ver + ".app"), "w") do |file|
          file.puts version
        end

        version
      end

      def uninstall(version = "1.0.0")
        super(version) do |path, version|
          File.delete(File.join(path, "bin", version + ".app"))
        end
      end
    end

    class SomeOtherInstaller < Juicer::Install::SomeMagicInstaller
      def install(version = nil)
        version ||= "1.0.0"
        super(version)
      end

      def latest
        "1.0.0"
      end
    end
  end
end

class TestInstallerBase < Test::Unit::TestCase
  def initialize(*args)
    super
    @juicer_home = File.expand_path(File.join("test", "data", ".juicer"))
  end

  def setup
    FileUtils.rm_rf @juicer_home
    @installer = Juicer::Install::SomeMagicInstaller.new(@juicer_home)
  end

  context "installation directory" do
    should "should be Juicer.home by default" do
      installer = Juicer::Install::SomeMagicInstaller.new
      assert_equal Juicer.home, installer.install_dir
    end

    should "override installation directory" do
      installer = Juicer::Install::SomeMagicInstaller.new("/home/baluba")
      assert_equal "/home/baluba", installer.install_dir
    end
  end

  context "latest" do
    should "raise NotImplementedError" do
      assert_raise NotImplementedError do
        @installer.latest
      end
    end
  end

  context "paths and name" do
    should "reflect installer class name" do
      assert_equal "lib/some_magic", @installer.path
    end

    should "reflect installer class name for bin path" do
      assert_equal "lib/some_magic/bin", @installer.bin_path
    end

    should "reflect class name in human name" do
      assert_equal "Some Magic", @installer.name
    end
  end

  context "already installed module" do
    should "report as installed" do
      assert !@installer.installed?("x.y.z")
      @installer.install("x.y.z")
      assert @installer.installed?("x.y.z")
    end

    should "fail re-installation" do
      @installer.install("1.0.0")

      assert_raise RuntimeError do
        @installer.install("1.0.0")
      end
    end
  end

  context "installation" do
    should "create bin and release folders" do
      assert_equal "1.0.0", @installer.install("1.0.0")
      assert File.exists?(File.join(@juicer_home, "lib/some_magic/bin"))
      assert File.exists?(File.join(@juicer_home, "lib/some_magic/1.0.0"))
    end
  end

  context "uninstall" do
    should "remove library path when only version is uninstalled" do
      @installer.install("1.0.0")
      @installer.uninstall("1.0.0")
      assert !File.exists?(File.join(@juicer_home, "lib/some_magic"))
    end

    should "keep other versions" do
      @installer.install("1.0.0")
      @installer.install("1.0.1")
      @installer.uninstall("1.0.0")
      assert !File.exists?(File.join(@juicer_home, "lib/some_magic/1.0.0"))
      assert File.exists?(File.join(@juicer_home, "lib/some_magic"))
    end
  end

  context "download" do
    # TODO: Don't download
    should "cache files" do
      File.expects(:delete).at_most(0)
      @installer.download("http://www.julienlecomte.net/yuicompressor/")
      filename = File.join(@juicer_home, "download/some_magic/yuicompressor")
      assert File.exists?(filename)
      @installer.download("http://www.julienlecomte.net/yuicompressor/")
    end

    should "redownload cached files when forced" do
      File.expects(:delete).at_most(1)
      @installer.download("http://www.julienlecomte.net/yuicompressor/")
      filename = File.join(@juicer_home, "download/some_magic/yuicompressor")
      assert File.exists?(filename)
      File.expects(:open).at_most(1)
      @installer.download("http://www.julienlecomte.net/yuicompressor/", true)
    end
  end

  context "installer dependencies" do
    should "not return true from installer when missing dependencies" do
      @installer.install

      installer = Juicer::Install::SomeMagicInstaller.new(@juicer_home)
      assert !installer.installed?("1.0.1"), "Installer should be installed"

      installer.dependency Juicer::Install::SomeOtherInstaller
      assert !installer.installed?("1.0.1"), "Installer should not report as being installed when missing dependencies"
    end

    should "install single dependency" do
      installer = Juicer::Install::SomeMagicInstaller.new(@juicer_home)
      installer.dependency Juicer::Install::SomeOtherInstaller
      installer.install "1.0.0"
      assert File.exists?(File.join(@juicer_home, "lib/some_magic/1.0.0"))
      assert File.exists?(File.join(@juicer_home, "lib/some_other/1.0.0"))
    end

    should "not raise error when they exist" do
      installer = Juicer::Install::SomeMagicInstaller.new(@juicer_home)
      installer.dependency Juicer::Install::SomeOtherInstaller

      dep = Juicer::Install::SomeOtherInstaller.new
      dep.install unless dep.installed?

      assert_nothing_raised do
        installer.install "1.0.0"
      end
    end

    should "get dependency from single symbol" do
      installer = Juicer::Install::SomeMagicInstaller.new(@juicer_home)
      installer.dependency :some_other
      installer.install "1.0.0"
      assert File.exists?(File.join(@juicer_home, "lib/some_magic/1.0.0"))
      assert File.exists?(File.join(@juicer_home, "lib/some_other/1.0.0"))
    end

    should "get dependency from single string" do
      installer = Juicer::Install::SomeMagicInstaller.new(@juicer_home)
      installer.dependency "some_other"
      installer.install "1.0.0"
      assert File.exists?(File.join(@juicer_home, "lib/some_magic/1.0.0"))
      assert File.exists?(File.join(@juicer_home, "lib/some_other/1.0.0"))
    end

    should "support multiple dependencies" do
      installer = Juicer::Install::SomeMagicInstaller.new(@juicer_home)
      installer.dependency :some_other
      installer.dependency :some_other, "2.0.4"
      installer.dependency :some_other, "3.0.5"
      installer.install "1.0.0"
      assert File.exists?(File.join(@juicer_home, "lib/some_magic/1.0.0"))
      assert File.exists?(File.join(@juicer_home, "lib/some_other/1.0.0"))
      assert File.exists?(File.join(@juicer_home, "lib/some_other/2.0.4"))
      assert File.exists?(File.join(@juicer_home, "lib/some_other/3.0.5"))
    end
  end

  context "resolving class" do
    should "accept class input" do
      assert_equal Juicer::Install::SomeMagicInstaller, Juicer::Install.get(Juicer::Install::SomeMagicInstaller)
    end

    should "accept symbol input" do
      assert_equal Juicer::Install::SomeMagicInstaller, Juicer::Install.get(:some_magic)
    end

    should "accept string input" do
      assert_equal Juicer::Install::SomeMagicInstaller, Juicer::Install.get("some_magic")
    end
  end
end
