require 'stringio'
require File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. test_helper])) unless defined?(Juicer)
require File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. .. lib juicer install base]))

# TODO: Do this better...
#module Kernel
#  def open(url)
#    str = StringIO.new
#    str.puts "1.0.0"
#    str
#  end
#end

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

  def test_default_installation_directory_should_be_juicer_home
    installer = Juicer::Install::SomeMagicInstaller.new
    assert_equal Juicer.home, installer.install_dir
  end

  def test_override_installation_directory
    installer = Juicer::Install::SomeMagicInstaller.new("/home/baluba")
    assert_equal "/home/baluba", installer.install_dir
  end

  def test_latest_method_should_raise_NotImplementedError
    assert_raise NotImplementedError do
      @installer.latest
    end
  end

  def test_path
    assert_equal "lib/some_magic", @installer.path
  end

  def test_bin_path
    assert_equal "lib/some_magic/bin", @installer.bin_path
  end

  def test_name
    assert_equal "Some Magic", @installer.name
  end

  def test_installed
    assert !@installer.installed?("x.y.z")
    @installer.install("x.y.z")
    assert @installer.installed?("x.y.z")
  end

  def test_installation_should_fail_when_already_installed
    @installer.install("1.0.0")

    assert_raise RuntimeError do
      @installer.install("1.0.0")
    end
  end

  def test_installation_should_create_bin_and_release_folders
    assert_equal "1.0.0", @installer.install("1.0.0")
    assert File.exists?(File.join(@juicer_home, "lib/some_magic/bin"))
    assert File.exists?(File.join(@juicer_home, "lib/some_magic/1.0.0"))
  end

  def test_uninstall_should_remove_library_path_when_only_version_is_uninstalled
    @installer.install("1.0.0")
    @installer.uninstall("1.0.0")
    assert !File.exists?(File.join(@juicer_home, "lib/some_magic"))
  end

  def test_uninstall_should_keep_other_versions
    @installer.install("1.0.0")
    @installer.install("1.0.1")
    @installer.uninstall("1.0.0")
    assert !File.exists?(File.join(@juicer_home, "lib/some_magic/1.0.0"))
    assert File.exists?(File.join(@juicer_home, "lib/some_magic"))
  end

  def test_download_should_cache_files_and_only_redownload_when_forced_to_do_so
    @installer.download("http://feeds.feedburner.com/cjno")
    filename = File.join(@juicer_home, "download/some_magic/cjno")
    assert File.exists?(filename)
    sleep(0.5)

    mtime = File.stat(filename).mtime
    @installer.download("http://feeds.feedburner.com/cjno")
    assert_equal mtime, File.stat(filename).mtime
    sleep(0.5)

    @installer.download("http://feeds.feedburner.com/cjno", true)
    assert_not_equal mtime, File.stat(filename).mtime
  end

  def test_installer_should_not_report_true_when_missing_dependencies
    @installer.install

    installer = Juicer::Install::SomeMagicInstaller.new(@juicer_home)
    assert !installer.installed?("1.0.1"), "Installer should be installed"

    installer.dependency Juicer::Install::SomeOtherInstaller
    assert !installer.installed?("1.0.1"), "Installer should not report as being installed when missing dependencies"
  end

  def installer_with_single_dependency_should_have_it_installed_on_install
    installer = Juicer::Install::SomeMagicInstaller.new(@juicer_home)
    installer.dependency Juicer::Install::SomeOtherInstaller
    installer.install "1.0.0"
    assert File.exists?(File.join(@juicer_home, "lib/some_magic/1.0.0"))
    assert File.exists?(File.join(@juicer_home, "lib/some_other/1.0.0"))
  end

  def test_installed_dependency_should_not_cause_error
    installer = Juicer::Install::SomeMagicInstaller.new(@juicer_home)
    installer.dependency Juicer::Install::SomeOtherInstaller

    dep = Juicer::Install::SomeOtherInstaller.new
    dep.install unless dep.installed?

    assert_nothing_raised do
      installer.install "1.0.0"
    end
  end

  def test_single_dependency_symbol
    installer = Juicer::Install::SomeMagicInstaller.new(@juicer_home)
    installer.dependency :some_other
    installer.install "1.0.0"
    assert File.exists?(File.join(@juicer_home, "lib/some_magic/1.0.0"))
    assert File.exists?(File.join(@juicer_home, "lib/some_other/1.0.0"))
  end

  def test_single_dependency_string
    installer = Juicer::Install::SomeMagicInstaller.new(@juicer_home)
    installer.dependency "some_other"
    installer.install "1.0.0"
    assert File.exists?(File.join(@juicer_home, "lib/some_magic/1.0.0"))
    assert File.exists?(File.join(@juicer_home, "lib/some_other/1.0.0"))
  end

  def test_multiple_dependencies
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

  def test_get_class
    assert_equal Juicer::Install::SomeMagicInstaller, Juicer::Install.get(Juicer::Install::SomeMagicInstaller)
  end

  def test_get_class_from_symbol
    assert_equal Juicer::Install::SomeMagicInstaller, Juicer::Install.get(:some_magic)
  end

  def test_get_class_from_string
    assert_equal Juicer::Install::SomeMagicInstaller, Juicer::Install.get("some_magic")
  end
end
