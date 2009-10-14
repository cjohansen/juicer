require "test_helper"

class TestJsLint < Test::Unit::TestCase
  def initialize(*args)
    @path = File.expand_path(path("../bin"))
    @file = path("jsltest.js")
    super
  end
  
  def setup
    FileUtils.mkdir(path("")) unless File.exists?(path(""))
    File.open(@file, "w") { |f| f.puts "" }
  end

  def teardown
    File.delete(@file)
  end

  context "verifying file with jslint" do
    should "shell out to rhino/jslint" do
      jslint = Juicer::JsLint.new(:bin_path => @path)
      jslint.expects(:execute).with("-jar \"#{@path}/rhino1_7R2-RC1.jar\" \"#{@path}/jslint-1.0.js\" \"#{@file}\"").returns("jslint: No problems")
      
      assert jslint.check(@file).ok?
    end
  end

  context "jslint report returns" do
    should "be a report object for valid files" do
      jslint = Juicer::JsLint.new(:bin_path => @path)
      jslint.expects(:execute).returns("jslint: No problems")

      assert_equal Juicer::JsLint::Report, jslint.check(@file).class
    end

    should "be a report object for invalid files" do
      jslint = Juicer::JsLint.new(:bin_path => @path)
      jslint.expects(:execute).returns("Wrong use of semicolon\nWrong blabla")
      
      assert_equal Juicer::JsLint::Report, jslint.check(path("not-ok.js")).class
    end
  end

  context "errors" do
    should "be available on report" do
      jslint = Juicer::JsLint.new(:bin_path => @path)
      jslint.expects(:execute).returns("Wrong use of semicolon\nWrong blabla\nWrong use of semicolon\nWrong blabla")

      assert_equal 2, jslint.check(@file).errors.length
    end

    should "be error objects" do
      jslint = Juicer::JsLint.new(:bin_path => @path)
      jslint.expects(:execute).returns("Wrong use of semicolon\nWrong blabla")

      error = jslint.check(@file).errors.first
      assert_equal Juicer::JsLint::Error, error.class
    end
  end
end
