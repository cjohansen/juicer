require "test_helper"

class TestJsLint < Test::Unit::TestCase
  def setup
    Juicer::Test::FileSetup.new.create
    #installer = Juicer::Install::JSLintInstaller.new path(".juicer")
    #installer.install unless installer.installed?

    @jslint = Juicer::JsLint.new(:bin_path => path("bin"))
  end

  context "verifying file with jslint" do
    should "pass valid file" do
      assert @jslint.check(path("ok.js")).ok?
    end

    should "not pas invalid file" do
      assert !@jslint.check(path("not-ok.js")).ok?
    end
  end

  context "jslint return type" do
    should "be a report object for valid files" do
      assert_equal Juicer::JsLint::Report, @jslint.check(path("ok.js")).class
    end

    should "be a report object for invalid files" do
      assert_equal Juicer::JsLint::Report, @jslint.check(path("not-ok.js")).class
    end
  end

  context "errors" do
    should "be available on report" do
      assert_equal 2, @jslint.check(path("not-ok.js")).errors.length
    end

    should "be error objects" do
      error = @jslint.check(path("not-ok.js")).errors.first
      assert_equal Juicer::JsLint::Error, error.class
    end
  end
end
