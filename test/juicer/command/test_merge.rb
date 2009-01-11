require File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. test_helper])) unless defined?(Juicer)

class TestMergeCommand < Test::Unit::TestCase

  def setup
    @io = StringIO.new
    @merge = Juicer::Command::Merge.new(Logger.new(@io))

    @file_setup = Juicer::Test::FileSetup.new($DATA_DIR)
    @file_setup.create!

    Juicer.home = path(".juicer")
    installer = Juicer::Install::YuiCompressorInstaller.new(Juicer.home)
    installer.install("2.4.1") unless installer.installed?("2.4.1")
  end

  def test_get_minifier_from_nil_minifyer
    @merge.instance_eval { @minifyer = nil }

    Juicer::Command::Merge.publicize_methods do
      assert_nil @merge.minifyer
    end
  end

  def test_get_minifier_from_empty_minifyer
    @merge.instance_eval { @minifyer = "" }

    Juicer::Command::Merge.publicize_methods do
      assert_nil @merge.minifyer
    end
  end

  def test_get_minifier_from_none_minifyer
    Juicer::Command::Merge.publicize_methods do
      @merge.instance_eval { @minifyer = "none" }
      assert_nil @merge.minifyer

      @merge.instance_eval { @minifyer = "None" }
      assert_nil @merge.minifyer

      @merge.instance_eval { @minifyer = "NONE" }
      assert_nil @merge.minifyer
    end
  end

  def test_get_minifyer
    Juicer::Command::Merge.publicize_methods do
      assert @merge.minifyer.is_a?(Juicer::Minifyer::Compressor)
    end
  end

  def test_output_name_from_file_should_have_suffix_prepended_with_min
    Juicer::Command::Merge.publicize_methods do
      assert_equal "test.min.js", @merge.output("test.js")
    end
  end

  def test_output_name_from_nothing_should_be_timestamp
    Juicer::Command::Merge.publicize_methods do
      assert_match(/\d{10}\.min\.tmp/, @merge.output)
    end
  end

  def test_output_name_instance_value
    Juicer::Command::Merge.publicize_methods do
      @merge.instance_eval { @output = "output.css" }
      assert_equal "output.css", @merge.output
      assert_equal "output.css", @merge.output("bleh.css")
    end
  end

  def test_merger_from_valid_type
    Juicer::Command::Merge.publicize_methods do
      assert_equal Juicer::Merger::JavaScriptMerger, @merge.merger("bleh.js")
    end
  end

  def test_merger_from_invalid_type
    Juicer::Command::Merge.publicize_methods do
      assert_equal Juicer::Merger::JavaScriptMerger, @merge.merger("bleh.txt")
      assert_match /Unknown type 'txt', defaulting to 'js'/, @io.string
    end
  end

  def test_merger_from_preset_type
    Juicer::Command::Merge.publicize_methods do
      @merge.instance_eval { @type = "css" }
      assert_equal Juicer::Merger::StylesheetMerger, @merge.merger
      assert_equal Juicer::Merger::StylesheetMerger, @merge.merger("bleh.txt")
    end
  end

  def test_merge_without_input
    assert_raise SystemExit do
      @merge.execute([])
    end
  end

  def test_merge_with_bogus_input
    assert_raise SystemExit do
      @merge.execute(["*.css", "bleh/*.js"])
    end
  end

  def test_unable_to_merge_on_existing_file
    assert_raise SystemExit do
      @merge.instance_eval { @output = path("a.css") }
      @merge.execute(path("a.css"))
      assert_match /Run again with --force to overwrite/, @io.string
    end
  end

  def test_update_output_when_force
   assert_nothing_raised do
     @merge.instance_eval { @force = true }
     @merge.execute(path("a.css"))
   end
  end

   def test_merge_successful
     File.delete(path("a.min.css")) if File.exists?(path("a.min.css"))
     @merge.instance_eval { @output = path("a.min.css") }
     assert @merge.execute(path("a1.css"))
     assert_equal IO.read(path("a.min.css")), "h2{font-size:10px}html{background:red}h1{font-size:12px}body{width:800px}"
   rescue Exception => e
     puts e.message
  end
end
