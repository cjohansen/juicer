require File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. test_helper])) unless defined?(Juicer)

class TestListCommand < Test::Unit::TestCase

  def setup
    @io = StringIO.new
    @command = Juicer::Command::List.new(@io)
  end

  def test_list_nothing
    assert_raise ArgumentError do
      @command.execute
    end

    assert_raise ArgumentError do
      @command.execute []
    end
  end

  def test_list_css_file
    @command.execute "test/data/a.css"

    msg = <<-STDOUT
Dependency chain for test/data/a.css:
  test/data/b.css
  test/data/a.css

    STDOUT

    assert_equal msg, @io.string
  end

  def test_list_js_file
    @command.execute "test/data/a.js"

    msg = <<-STDOUT
Dependency chain for test/data/a.js:
  test/data/b.js
  test/data/a.js

    STDOUT

    assert_equal msg, @io.string
  end

  def test_list_several_files
    @command.execute "test/data/*.js"

    msg = <<-STDOUT
Dependency chain for test/data/a.js:
  test/data/b.js
  test/data/a.js

Dependency chain for test/data/b.js:
  test/data/a.js
  test/data/b.js

    STDOUT

    assert_equal msg, @io.string
  end

  def test_list_files_unable_to_guess_type
    assert_raise FileNotFoundError do
      @command.execute("test/data/*.txt")
    end
  end
end
