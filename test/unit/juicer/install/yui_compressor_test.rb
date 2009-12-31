require "test_helper"

class TestYuiCompressorInstall < Test::Unit::TestCase
  def setup
    @installer = Juicer::Install::YuiCompressorInstaller.new(path(".juicer"))
  end

  def teardown
    FileUtils.rm_rf(path(".juicer/lib")) if File.exists?(path(".juicer/lib"))
  end

  def test_check_installation
    assert !@installer.installed?
  end

  def test_install_should_download_jar_and_readme
    @installer.install

    assert File.exists?(path(".juicer"))
    assert File.exists?(path(".juicer/lib"))
    assert File.exists?(path(".juicer/lib/yui_compressor"))
    assert File.exists?(path(".juicer/lib/yui_compressor/bin"))
    assert_match(/yuicompressor-\d\.\d\.\d\.jar/, Dir.glob(path(".juicer/lib/yui_compressor/bin/*"))[0])

    files = Dir.glob(path(".juicer/lib/yui_compressor/*.*.*/**/*"))
    assert_equal ["CHANGELOG", "README"], files.collect { |file| file.split("/").pop }.sort
  end

  def test_uninstall_should_remove_all_files_and_empty_directories
    @installer.install
    assert File.exists?(path(".juicer/lib/yui_compressor/bin"))
    assert_equal 3, Dir.glob(path(".juicer/lib/yui_compressor/**/*")).find_all { |f| File.file?(f) }.length

    @installer.uninstall
    assert !File.exists?(path(".juicer/lib/yui_compressor"))
  end

  # def test_install_specific_version
  #   @installer.install("2.3.5")

  #   assert File.exists?(path(".juicer/lib/yui_compressor/bin"))
  #   assert File.exists?(path(".juicer/lib/yui_compressor/2.3.5"))
  #   assert_equal "yuicompressor-2.3.5.jar", File.basename(Dir.glob(path(".juicer/lib/yui_compressor/bin/*"))[0])
  # end

  # def test_uninstall_should_leave_directories_when_other_versions_are_installed
  #   @installer.install
  #   @installer.install("2.3.5")
  #   assert File.exists?(path(".juicer/lib/yui_compressor/bin"))
  #   assert_equal 6, Dir.glob(path(".juicer/lib/yui_compressor/**/*")).find_all { |f| File.file?(f) }.length

  #   @installer.uninstall("2.3.5")
  #   assert File.exists?(path(".juicer/lib/yui_compressor"))
  #   assert_equal 3, Dir.glob(path(".juicer/lib/yui_compressor/**/*")).find_all { |f| File.file?(f) }.length
  # end
end
