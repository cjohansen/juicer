require File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. test_helper])) unless defined?(Juicer)

class TestYuiCompressorInstall < Test::Unit::TestCase
  def teardown
    FileUtils.rm_rf(path("juicer_home")) if File.exists?(path("juicer_home"))
  end

  def test_check_installation
    assert !Juicer::Install::YuiCompressorInstaller.installed?(path("juicer_home"))
  end

  def test_install_should_download_jar_and_readme
    Juicer::Install::YuiCompressorInstaller.install(path("juicer_home"))

    assert File.exists?(path("juicer_home"))
    assert File.exists?(path("juicer_home/lib"))
    assert File.exists?(path("juicer_home/lib/yui_compressor"))
    assert File.exists?(path("juicer_home/lib/yui_compressor/bin"))
    assert_match(/yuicompressor-\d\.\d\.\d\.jar/, Dir.glob(path("juicer_home/lib/yui_compressor/bin/*"))[0])

    files = Dir.glob(path("juicer_home/lib/yui_compressor/*.*.*/**/*"))
    assert_equal ["CHANGELOG", "README"], files.collect { |file| file.split("/").pop }.sort
  end

  def test_uninstall_should_remove_all_files_and_empty_directories
    Juicer::Install::YuiCompressorInstaller.install(path("juicer_home"))
    assert File.exists?(path("juicer_home/lib/yui_compressor/bin"))
    assert_equal 3, Dir.glob(path("juicer_home/lib/yui_compressor/**/*")).find_all { |f| File.file?(f) }.length

    Juicer::Install::YuiCompressorInstaller.uninstall(path("juicer_home"))
    assert !File.exists?(path("juicer_home/lib/yui"))
  end

  def test_install_specific_version
    Juicer::Install::YuiCompressorInstaller.install(path("juicer_home"), "2.3.5")

    assert File.exists?(path("juicer_home/lib/yui_compressor/bin"))
    assert File.exists?(path("juicer_home/lib/yui_compressor/2.3.5"))
    assert_equal "yuicompressor-2.3.5.jar", Dir.glob(path("juicer_home/lib/yui_compressor/bin/*"))[0]
  end

  def test_uninstall_should_leave_directories_when_other_versions_are_installed
    Juicer::Install::YuiCompressorInstaller.install(path("juicer_home"))
    Juicer::Install::YuiCompressorInstaller.install(path("juicer_home"), "2.3.5")
    assert File.exists?(path("juicer_home/lib/yui_compressor/bin"))
    assert_equal 6, Dir.glob(path("juicer_home/lib/yui_compressor/**/*")).find_all { |f| File.file?(f) }.length

    Juicer::Install::YuiCompressorInstaller.uninstall(path("juicer_home"), "2.3.5")
    assert File.exists?(path("juicer_home/lib/yui"))
    assert_equal 3, Dir.glob(path("juicer_home/lib/yui_compressor/**/*")).find_all { |f| File.file?(f) }.length
  end
end
