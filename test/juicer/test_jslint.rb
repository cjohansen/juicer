require File.expand_path(File.join(File.dirname(__FILE__), %w[.. test_helper])) unless defined?(Juicer)

class TestJsLint < Test::Unit::TestCase

  def setup
    @jslint = Juicer::JsLint.new(:bin_path => Juicer.home)

    File.open(path("ok.js"), "w") do |file|
      js = <<-JS
function hey() {
    alert("Hey");
}
      JS

      file.puts js
    end

    File.open(path("not-ok.js"), "w") do |file|
      js = <<-JS
var a = 34
b = 78;
      JS

      file.puts js
    end
  end

  def teardown
    File.delete(path("ok.js"))
    File.delete(path("not-ok.js"))
  end

  def test_check_valid_file
    assert @jslint.check(path("ok.js")).ok?
  end

  def test_invalid_file
    assert !@jslint.check(path("not-ok.js")).ok?
  end

  def test_check_return_type
    assert_equal Juicer::JsLint::Report, @jslint.check(path("ok.js")).class
    assert_equal Juicer::JsLint::Report, @jslint.check(path("not-ok.js")).class
  end

  def test_error_list
    assert_equal 2, @jslint.check(path("not-ok.js")).errors.length
  end

  def test_errors
    error = @jslint.check(path("not-ok.js")).errors.first

    assert_equal Juicer::JsLint::Error, error.class

  end
end
