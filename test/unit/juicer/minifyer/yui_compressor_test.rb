require "test_helper"

class TestYuiCompressor < Test::Unit::TestCase
  def setup
    @jar = "yuicompressor-2.4.2.jar"
    @input = "in-file.css"
    @output = "out-file.css"
    @cmd = %Q{-jar "#@jar"}
    @yui_compressor = Juicer::Minifyer::YuiCompressor.new
    @yui_compressor.stubs(:locate_jar).returns(@jar)
  end

  context "#save" do
    should "overwrite existing file" do
      @yui_compressor.expects(:execute).with(%Q{#@cmd -o "#@output" "#@output"})
      @yui_compressor.save(@output)
    end

    should "use provided symbol type" do
      @yui_compressor.expects(:execute).with(%Q{#@cmd -o "#@output" "#@input"})
      @yui_compressor.save(@input, @output, :css)
    end

    should "use provided string type" do
      @yui_compressor.expects(:execute).with(%Q{#@cmd -o "#@output" "#@input"})
      @yui_compressor.save(@input, @output, "css")
    end

    should "write compressed input to output" do
      @yui_compressor.expects(:execute).with(%Q{#@cmd -o "#@output" "#@input"})
      @yui_compressor.save(@input, @output)
    end

    should "create non-existant path" do
      output = "some/nested/directory"
      @yui_compressor.expects(:execute).with(%Q{#@cmd -o "#{output}/file.css" "#@input"})
      FileUtils.expects(:mkdir_p).with(output)
      @yui_compressor.save(@input, "#{output}/file.css")
    end
  end

  context "locating jar" do
    setup do
      # Avoid developer env settings
      @yuic_home = ENV['YUIC_HOME']
      ENV.delete('YUIC_HOME')
    end

    teardown do
      ENV['YUIC_HOME'] = @yuic_home
      File.delete('yuicompressor-2.3.4.jar') if File.exists?('yuicompressor-2.3.4.jar')
      File.delete('yuicompressor-2.3.5.jar') if File.exists?('yuicompressor-2.3.5.jar')
      File.delete('yuicompressor.jar') if File.exists?('yuicompressor.jar')
      FileUtils.rm_rf("another") if File.exists?("another")
    end

    should "not find jar when no jars on path" do
      Juicer::Minifyer::YuiCompressor.publicize_methods do
        yui_compressor = Juicer::Minifyer::YuiCompressor.new

        assert_nil yui_compressor.locate_jar
      end
    end

    should "find only jar in path" do
      Juicer::Minifyer::YuiCompressor.publicize_methods do
        File.open('yuicompressor-2.3.4.jar', 'w') { |f| f.puts '' }
        yui_compressor = Juicer::Minifyer::YuiCompressor.new

        assert_equal File.expand_path('yuicompressor-2.3.4.jar'), yui_compressor.locate_jar
      end
    end

    should "find most recent of two jars on path" do
      Juicer::Minifyer::YuiCompressor.publicize_methods do
        # Create files
        File.open('yuicompressor-2.3.4.jar', 'w') { |f| f.puts '' }
        File.open('yuicompressor-2.3.5.jar', 'w') { |f| f.puts '' }

        yui_compressor = Juicer::Minifyer::YuiCompressor.new

        # Test
        assert_equal File.expand_path('yuicompressor-2.3.5.jar'), yui_compressor.locate_jar
      end
    end

    should "find most recent of three jar files on path" do
      Juicer::Minifyer::YuiCompressor.publicize_methods do
        # Create files
        File.open('yuicompressor-2.3.4.jar', 'w') { |f| f.puts '' }
        File.open('yuicompressor-2.3.5.jar', 'w') { |f| f.puts '' }
        File.open('yuicompressor.jar', 'w') { |f| f.puts '' }

        yui_compressor = Juicer::Minifyer::YuiCompressor.new

        # Test
        assert_equal File.expand_path('yuicompressor.jar'), yui_compressor.locate_jar
      end
    end

    should "find jar in custom directory" do
      Juicer::Minifyer::YuiCompressor.publicize_methods do
        # Prepare
        Dir.mkdir('another')
        File.open('another/yuicompressor-2.3.4.jar', 'w') { |f| f.puts "" }

        yui_compressor = Juicer::Minifyer::YuiCompressor.new

        # Test
        assert_nil yui_compressor.locate_jar
        yui_compressor = Juicer::Minifyer::YuiCompressor.new({ :bin_path => 'another' })
        assert_equal File.expand_path('another/yuicompressor-2.3.4.jar'), yui_compressor.locate_jar
      end
    end
  end
end
