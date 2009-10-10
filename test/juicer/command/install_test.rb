require "test_helper"

class TestInstallCommand < Test::Unit::TestCase
  def setup
    @io = StringIO.new
    @command = Juicer::Command::Install.new(Logger.new(@io))
    FileUtils.rm_rf(path(".juicer/lib")) if File.exists?(path(".juicer/lib"))
  end

  context "checking version" do
    should "bring up latest from installer" do
      assert_equal "1.0", @command.version(Juicer::Install::JSLintInstaller.new)
    end

    should "use explicit version" do
      @command.instance_eval { @version = "1.0.1" }
      assert_equal "1.0.1", @command.version(Juicer::Install::JSLintInstaller.new)
    end
  end

  context "executing command" do
    should "require atleast one argument" do
      assert_raise ArgumentError do
        @command.execute
      end
    end

    should "install single library" do
      installer = Juicer::Install::JSLintInstaller.new(path(".juicer"))
      assert !installer.installed?

      @command.instance_eval { @path = path(".juicer") }
      @command.execute("jslint")
      
      assert installer.installed?
    end

    should "not install already installed library" do
      installer = Juicer::Install::JSLintInstaller.new(path(".juicer"))
      installer.install
      assert installer.installed?

      @command.execute("jslint")
      assert_match(/is already installed in/, @io.string)
    end

    should "install specific version" do
      installer = Juicer::Install::JSLintInstaller.new(path(".juicer"))
      assert !installer.installed?("0.9")

      @command.instance_eval { @path = path(".juicer") }
      @command.instance_eval { @version = "0.9" }
      @command.execute("jslint")
      
      assert installer.installed?("0.9")
    end
  end
end
