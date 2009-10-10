require File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. test_helper])) unless defined?(Juicer)

class TestVerifyCommand < Test::Unit::TestCase
  def setup
    @io = StringIO.new
    @command = Juicer::Command::Verify.new(Logger.new(@io))
    @path = Dir.pwd
    @juicer = Juicer.home
  end

  def teardown
    Dir.chdir(@path)
    Juicer.home = @juicer
  end

  context "executing command" do
    should "fail with no files" do
      assert_raise ArgumentError do
        @command.execute []
      end
    end

    should "fail if installer is not found" do
      Juicer.home = path("somewhere")
      Dir.chdir("lib")
      command = Juicer::Command::Verify.new(Logger.new(@io))

      assert_raise FileNotFoundError do
        command.execute path("a.js")
      end
    end

    should "verify several files" do
      @command.execute([path("ok.js"), path("not-ok.js"), path("a.js")])
      assert_match(/OK!/, @io.string)
      assert_match(/Problems detected/, @io.string)
    end
  end
end
