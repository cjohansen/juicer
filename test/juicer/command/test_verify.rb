require File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. test_helper])) unless defined?(Juicer)

class TestVerifyCommand < Test::Unit::TestCase

  def setup
    @io = StringIO.new
    @command = Juicer::Command::Verify.new(Logger.new(@io))
  end

  def test_no_files
    assert_raise ArgumentError do
      @command.execute []
    end
  end

  def test_installer_not_found
    Juicer.home = path("somewhere")

    assert_raise FileNotFoundError do
      @command.execute path("a.js")
    end
  end

  def test_verify_several_files
    Juicer.home = path(".juicer")
    installer = Juicer::Install::JSLintInstaller.new(path(".juicer"))
    installer.install unless installer.installed?

    @command.execute([path("ok.js"), path("not-ok.js"), path("a.js")])
    assert_match(/OK!/, @io.string)
    assert_match(/Problems detected/, @io.string)
  end
end
