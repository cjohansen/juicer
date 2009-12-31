require "test_helper"

class TestJsLintInstaller < Test::Unit::TestCase
  def setup
    @installer = Juicer::Install::JSLintInstaller.new(path(".juicer"))
  end

  def teardown
    FileUtils.rm_rf(path(".juicer/lib")) if File.exists?(path(".juicer/lib"))
  end

  def test_install_should_download_js
    @installer.install unless @installer.installed?

    assert File.exists?(path(".juicer"))
    assert File.exists?(path(".juicer/lib"))
    assert File.exists?(path(".juicer/lib/jslint"))
    assert File.exists?(path(".juicer/lib/jslint/bin"))
    assert_match(/jslint-\d\.\d\.js/, Dir.glob(path(".juicer/lib/jslint/bin/*"))[0])
  end

  def test_uninstall_should_remove_all_files_and_empty_directories
    @installer.install
    assert File.exists?(path(".juicer/lib/jslint/bin"))
    assert_equal 1, Dir.glob(path(".juicer/lib/jslint/**/*")).find_all { |f| File.file?(f) }.length

    @installer.uninstall
    assert !File.exists?(path(".juicer/lib/jslint"))
  end

  def test_install_specific_version
    @installer.install("1.0")

    assert File.exists?(path(".juicer/lib/jslint/bin"))
    assert_equal "jslint-1.0.js", File.basename(Dir.glob(path(".juicer/lib/jslint/bin/*"))[0])
  end

  def test_install_should_install_rhino_also
    assert !File.exists?(path(".juicer/lib/rhino"))
    @installer.install
    assert File.exists?(path(".juicer/lib/rhino"))
 end

  def test_uninstall_should_leave_directories_when_other_versions_are_installed
    @installer.install
    @installer.install("1.1")
    assert File.exists?(path(".juicer/lib/jslint/bin"))
    assert_equal 2, Dir.glob(path(".juicer/lib/jslint/**/*")).find_all { |f| File.file?(f) }.length

    @installer.uninstall("1.1")
    assert File.exists?(path(".juicer/lib/jslint"))
    assert_equal 1, Dir.glob(path(".juicer/lib/jslint/**/*")).find_all { |f| File.file?(f) }.length
  end
end
