require File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. test_helper])) unless defined?(Juicer)

class TestInstallCommand < Test::Unit::TestCase

  def setup
    @io = StringIO.new
    @command = Juicer::Command::Install.new(Logger.new(@io))
    FileUtils.rm_rf(path(".juicer/lib")) if File.exists?(path(".juicer/lib"))
  end

  def test_default_version_should_bring_up_latest_from_installer
    assert_equal "1.0", @command.version(Juicer::Install::JSLintInstaller.new)
  end

  def test_explicit_version_should_not_be_overridden
    @command.instance_eval { @version = "1.0.1" }
    assert_equal "1.0.1", @command.version(Juicer::Install::JSLintInstaller.new)
  end

  def test_execute_should_require_atleast_one_argument
    assert_raise ArgumentError do
      @command.execute
    end
  end

  def test_install_single_lib
    installer = Juicer::Install::JSLintInstaller.new(path(".juicer"))
    assert !installer.installed?

    @command.instance_eval { @path = path(".juicer") }
    @command.execute("jslint")
    assert installer.installed?
  end

  def test_install_already_installed_lib
    installer = Juicer::Install::JSLintInstaller.new(path(".juicer"))
    installer.install
    assert installer.installed?

    @command.execute("jslint")
    assert_match(/is already installed in/, @io.string)
  end

  def test_install_specific_version
    installer = Juicer::Install::JSLintInstaller.new(path(".juicer"))
    assert !installer.installed?("0.9")

    @command.instance_eval { @path = path(".juicer") }
    @command.instance_eval { @version = "0.9" }
    @command.execute("jslint")
    assert installer.installed?("0.9")
  end
end
