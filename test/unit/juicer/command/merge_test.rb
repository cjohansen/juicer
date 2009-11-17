require "test_helper"

class TestMergeCommand < Test::Unit::TestCase
  def setup
    @io = StringIO.new
    @merge = Juicer::Command::Merge.new(Logger.new(@io))

    Juicer::Test::FileSetup.new.create

    ["a.min.css", "not-ok.min.js"].each { |f| File.delete(path(f)) if File.exists?(path(f)) }
  end

  context "getting minifyer" do
    should "return nil when minifyer is not specified" do
      @merge.instance_eval { @minifyer = nil }

      Juicer::Command::Merge.publicize_methods do
        assert_nil @merge.minifyer
      end
    end

    should "return nil when minifyer is empty string" do
      @merge.instance_eval { @minifyer = "" }

      Juicer::Command::Merge.publicize_methods do
        assert_nil @merge.minifyer
      end
    end

    should "return nil when minifyer is 'none'" do
      Juicer::Command::Merge.publicize_methods do
        @merge.instance_eval { @minifyer = "none" }
        assert_nil @merge.minifyer

        @merge.instance_eval { @minifyer = "None" }
        assert_nil @merge.minifyer

        @merge.instance_eval { @minifyer = "NONE" }
        assert_nil @merge.minifyer
      end
    end

    should "get specified minifyer" do
      Juicer::Command::Merge.publicize_methods do
        assert @merge.minifyer.class == Juicer::Minifyer::YuiCompressor
      end
    end
  end

  context "output name" do
    should "have suffix prepended with min when input is a file" do
      Juicer::Command::Merge.publicize_methods do
        assert_equal File.expand_path("test.min.js"), @merge.output("test.js")
      end
    end

    should "be timestamp when input is not provided" do
      Juicer::Command::Merge.publicize_methods do
        assert_match(/\d{10}\.min\.tmp/, @merge.output)
      end
    end

    should "be instance variable output" do
      Juicer::Command::Merge.publicize_methods do
        @merge.instance_eval { @output = "output.css" }
        assert_equal File.expand_path("output.css"), @merge.output
        assert_equal File.expand_path("output.css"), @merge.output("bleh.css")
      end
    end

    should "should be generated when output is directory" do
      Juicer::Command::Merge.publicize_methods do
        @merge.instance_eval { @output = path("css") }
        assert_equal File.join(path("css"), "file.min.css"), @merge.output("file.css")
      end
    end
  end

  context "get merger" do
    should "return object from valid type" do
      Juicer::Command::Merge.publicize_methods do
        assert_equal Juicer::Merger::JavaScriptMerger, @merge.merger("bleh.js")
      end
    end

    should "default to js for invalid type" do
      Juicer::Command::Merge.publicize_methods do
        assert_equal Juicer::Merger::JavaScriptMerger, @merge.merger("bleh.txt")
        assert_match(/Unknown type 'txt', defaulting to 'js'/, @io.string)
      end
    end

    should "use preset type" do
      Juicer::Command::Merge.publicize_methods do
        @merge.instance_eval { @type = "css" }
        assert_equal Juicer::Merger::StylesheetMerger, @merge.merger
        assert_equal Juicer::Merger::StylesheetMerger, @merge.merger("bleh.txt")
      end
    end
  end

  context "merging" do
    should "raise error without input" do
      assert_raise SystemExit do
        @merge.execute([])
      end
    end

    should "raise error with bogus input" do
      assert_raise SystemExit do
        @merge.execute(["*.css", "bleh/*.js"])
      end
    end

    should "fail if output exists" do
      assert_raise SystemExit do
        @merge.instance_eval { @output = path("a.css") }
        @merge.execute(path("a.css"))
        assert_match(/Run again with --force to overwrite/, @io.string)
      end
    end

    should "update output when force option is set" do
      assert_nothing_raised do
        @merge.instance_eval { @force = true }
        @merge.execute(path("a.css"))
      end
    end

    should "merge files" do
      begin
        @merge.instance_eval { @output = path("a.min.css") }
        assert @merge.execute(path("a1.css"))
        assert_match "h2{font-size:10px;}html{background:red;}h1{font-size:12px;}body{width:800px;}", IO.read(path("a.min.css"))
      rescue Test::Unit::AssertionFailedError => err
        raise err
      rescue Exception => err
        puts err.message
      end
    end

    should "raise error when jslint does not pass" do
      assert_raise SystemExit do
        @merge.execute(path("not-ok.js"))
        assert_match(/Problems were detected during verification/, @io.string)
        assert_no_match(/Ignoring detected problems/, @io.string)
      end
    end

    should "ignore jslint problems" do
      @merge.instance_eval { @ignore = true }
      
      assert_nothing_raised do
        @merge.execute(path("not-ok.js"))
        assert_match(/Problems were detected during verification/, @io.string)
        assert_match(/Ignoring detected problems/, @io.string)
      end
    end
  
    should_eventually "warn about duplicated image urls for embedding"
  end
end
