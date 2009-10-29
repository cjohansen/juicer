require "test_helper"

class TestRhinoInstaller < Test::Unit::TestCase
  def setup
    @installer = Juicer::Install::RhinoInstaller.new(path(".juicer"))
  end

  def teardown
    FileUtils.rm_rf(path(".juicer/lib")) if File.exists?(path(".juicer/lib"))
  end

  def test_check_installation
    FileUtils.rm_rf(path(".juicer/lib")) if File.exists?(path(".juicer/lib"))
    assert !@installer.installed?
  end

  def test_install_should_download_jar_and_license
    @installer.install

    assert File.exists?(path(".juicer"))
    assert File.exists?(path(".juicer/lib"))
    assert File.exists?(path(".juicer/lib/rhino"))
    assert File.exists?(path(".juicer/lib/rhino/bin"))
    assert_match(/rhino\d\_\d[^\.]*\.jar/, Dir.glob(path(".juicer/lib/rhino/bin/*"))[0])

    files = Dir.glob(path(".juicer/lib/rhino/*_*/**/*"))
    assert_equal ["LICENSE.txt"], files.collect { |file| file.split("/").pop }.sort
  end

  def test_uninstall_should_remove_all_files_and_empty_directories
    @installer.install
    assert File.exists?(path(".juicer/lib/rhino/bin"))
    assert_equal 2, Dir.glob(path(".juicer/lib/rhino/**/*")).find_all { |f| File.file?(f) }.length

    @installer.uninstall
    assert !File.exists?(path(".juicer/lib/rhino"))
  end

  def test_install_specific_version
    @installer.install("1.7R2-RC1")

    assert File.exists?(path(".juicer/lib/rhino/bin"))
    assert File.exists?(path(".juicer/lib/rhino/1_7R2-RC1"))
    assert_equal "rhino1_7R2-RC1.jar", File.basename(Dir.glob(path(".juicer/lib/rhino/bin/*"))[0])
  end

  def test_uninstall_should_leave_directories_when_other_versions_are_installed
    @installer.install
    @installer.install("1.7R1")
    assert File.exists?(path(".juicer/lib/rhino/bin"))
    assert_equal 3, Dir.glob(path(".juicer/lib/rhino/**/*")).find_all { |f| File.file?(f) }.length

    @installer.uninstall("1.7R2-RC1")
    assert File.exists?(path(".juicer/lib/rhino"))
    assert_equal 1, Dir.glob(path(".juicer/lib/rhino/**/*")).find_all { |f| File.file?(f) }.length
 end
end
