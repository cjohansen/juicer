require File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. test_helper])) unless defined?(Juicer)
require File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. .. lib juicer install base]))

module Juicer
  class SomeMagicInstaller < Juicer::Install::Base
  end
end

class TestInstallerBase < Test::Unit::TestCase

  def teardown
    installer = Juicer::SomeMagicInstaller.new
    FileUtils.rm_rf installer.path
  end

  def test_default_install_dir_should_be_juicer_home
    installer = Juicer::SomeMagicInstaller.new
    assert_equal Juicer.home, installer.install_dir
  end

  def test_set_install_dir
    installer = Juicer::SomeMagicInstaller.new("/home/baluba")
    assert_equal "/home/baluba", installer.install_dir
  end

  def test_latest_not_implemented_should_raise_error
    installer = Juicer::SomeMagicInstaller.new

    assert_raise NotImplementedError do
      installer.latest
    end
  end

  def test_path
    installer = Juicer::SomeMagicInstaller.new
    assert_equal "lib/some_magic", installer.path
  end

  def test_name
    installer = Juicer::SomeMagicInstaller.new
    assert_equal "Some Magic", installer.name
  end

  def test_installed
    installer = Juicer::SomeMagicInstaller.new
    assert !installer.installed?("x.y.z")
  end

  def test_install
    installer = Juicer::SomeMagicInstaller.new
    assert_equal "1.0.0", installer.install("1.0.0")
    assert File.exists?(File.join(Juicer.home, "lib/some_magic/bin"))
    assert File.exists?(File.join(Juicer.home, "lib/some_magic/1.0.0"))
  end

  def test_uninstall
    installer = Juicer::SomeMagicInstaller.new
    installer.install("1.0.0")
    installer.uninstall("1.0.0")
    assert !File.exists?(File.join(Juicer.home, "lib/some_magic"))

    installer.install("1.0.0")
    installer.install("1.0.1")
    installer.uninstall("1.0.0")
    assert !File.exists?(File.join(Juicer.home, "lib/some_magic/1.0.0"))
    assert File.exists?(File.join(Juicer.home, "lib/some_magic"))
  end

  def test_download
    installer = Juicer::SomeMagicInstaller.new
    installer.download("http://feeds.feedburner.com/cjno")
    filename = File.join(Juicer.home, "download/some_magic/cjno")
    assert File.exists?(filename)

    mtime = File.stat(filename)
    installer.download("http://feeds.feedburner.com/cjno")
    assert_equal mtime, File.stat(filename)

    installer.download("http://feeds.feedburner.com/cjno", true)
    assert_not_equal mtime, File.stat(filename)
  end
end
