require File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. test_helper])) unless defined?(Juicer)

class TestYuiCompressor < Test::Unit::TestCase

  def setup
    @path = ENV.key?('YUI_HOME') ? ENV['YUI_HOME'] : File.expand_path('~/sources/yuicompressor-2.3.5/build')
    # @path = File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. ..]))
    @yui_compressor = Juicer::Minifyer::YuiCompressor.new({ :bin_path => @path })
    @file_setup = Juicer::Test::FileSetup.new($DATA_DIR)
    @file_setup.create!
    @file = File.join($DATA_DIR, 'out.min.css')
  end

  def teardown
    File.delete(@file) if File.exists?(@file)
  end

  def test_compress
    contents = @yui_compressor.compress(File.join($DATA_DIR, 'a.css'))
    assert_equal "@import 'b.css';", contents

    filename = File.join($DATA_DIR, 'a-minified.css')
    assert @yui_compressor.compress(File.join($DATA_DIR, 'a.css'), filename)
    assert_equal "@import 'b.css';", IO.read(filename)
    File.delete(filename)
  end

  def test_command
    Juicer::Minifyer::YuiCompressor.publicize_methods do
      cmd = 'java -jar ' + @path + '/yuicompressor-2.3.5.jar --type css'
      assert_equal cmd, @yui_compressor.command('css')

      @yui_compressor.nomunge = true
      cmd += ' --nomunge'
      assert_equal cmd, @yui_compressor.command('css')
    end
  end

  def test_locate_jar
    Juicer::Minifyer::YuiCompressor.publicize_methods do
      # No env, no option, and no fil in cwd
      ENV.delete('YUIC_HOME')
      @yui_compressor = Juicer::Minifyer::YuiCompressor.new
      assert_nil @yui_compressor.locate_jar

      # One file in cwd
      File.open('yuicompressor-2.3.4.jar', 'w') { |f| f.puts '' }
      assert_equal File.expand_path('yuicompressor-2.3.4.jar'), @yui_compressor.locate_jar

      # Two files in cwd
      File.open('yuicompressor-2.3.5.jar', 'w') { |f| f.puts '' }
      assert_equal File.expand_path('yuicompressor-2.3.5.jar'), @yui_compressor.locate_jar

      # Three files in cwd
      File.open('yuicompressor.jar', 'w') { |f| f.puts '' }
      assert_equal File.expand_path('yuicompressor.jar'), @yui_compressor.locate_jar

      # Specify another directory
      Dir.mkdir('another')
      Dir.chdir('another')
      File.open('yuicompressor-2.3.4.jar', 'w')
      Dir.chdir('..')
      assert_equal File.expand_path('yuicompressor.jar'), @yui_compressor.locate_jar
      @yui_compressor = Juicer::Minifyer::YuiCompressor.new({ :bin_path => 'another' })
      assert_equal File.expand_path('another/yuicompressor-2.3.4.jar'), @yui_compressor.locate_jar

      # Cleanup
      FileUtils.rm('yuicompressor-2.3.4.jar')
      FileUtils.rm('yuicompressor-2.3.5.jar')
      FileUtils.rm('yuicompressor.jar')
      FileUtils.rm_rf('another')
    end
  end
end
