require "test_helper"

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
      files = %w[file1.js file2.js file3.js]
      ok = "OK!\njslint: No problems"

      Juicer::Command::Verify.any_instance.expects(:files).with(files).returns(files)
      Juicer::JsLint.any_instance.expects(:check).with(files[0]).returns(Juicer::JsLint::Report.new)
      Juicer::JsLint.any_instance.expects(:check).with(files[1]).returns(Juicer::JsLint::Report.new(["Oops"]))
      Juicer::JsLint.any_instance.expects(:check).with(files[2]).returns(Juicer::JsLint::Report.new)
      
      @command.execute(files)
     
      assert_match(/OK!/, @io.string)
      assert_match(/Problems detected/, @io.string)
    end
  end
end
