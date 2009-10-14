require "test_helper"

class TestYuiCompressor < Test::Unit::TestCase
  def setup
    @path = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "..", "bin"))
    @yui_compressor = Juicer::Minifyer::YuiCompressor.new({ :bin_path => @path })
    Juicer::Test::FileSetup.new.create
    @file = path('out.min.css')
  end

  def teardown
    File.delete(@file) if @file && File.exists?(@file)
    File.delete(path("a-1.css")) if File.exists?(path("a-1.css"))
  end

  def test_save_overwrite
    FileUtils.cp(path('a.css'), path('a-1.css'))
    @yui_compressor.save(path('a-1.css'))
    assert_equal "@import 'b.css';", IO.read(path('a-1.css'))
  end

  def test_save_with_symbol_type
    @yui_compressor.save(path('a.css'), path('a-1.css'), :css)
    assert_equal "@import 'b.css';", IO.read(path('a-1.css'))
    File.delete(path('a-1.css'))
  end

  def test_save_with_string_type
    @yui_compressor.save(path('a.css'), path('a-1.css'), "css")
    assert_equal "@import 'b.css';", IO.read(path('a-1.css'))
    File.delete(path('a-1.css'))
  end

  def test_save_other_file
    @yui_compressor.save(path('a.css'), path('a-1.css'))
    assert_equal "@import 'b.css';", IO.read(path('a-1.css'))
    assert_not_equal IO.read(path('a-1.css')), IO.read(path('a.css'))
    File.delete(path('a-1.css'))
  end

  def test_save_should_create_non_existant_path
    @yui_compressor.save(path('a.css'), path('bleh/blah/a-1.css'))
    assert File.exists? path('bleh/blah/a-1.css')
    FileUtils.rm_rf(path('bleh'))
  end

#  def test_command
#    Juicer::Minifyer::YuiCompressor.publicize_methods do
#      cmd = /java -jar #{@path.sub('2.3.5', '\d\.\d\.\d')}\/yuicompressor-\d\.\d\.\d\.jar --type css/
#      assert_match cmd, @yui_compressor.command('css')

#      @yui_compressor.no_munge = true
#      cmd = /#{cmd} --no-munge/
#      assert_match cmd, @yui_compressor.command('css')
#    end
#  end

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
