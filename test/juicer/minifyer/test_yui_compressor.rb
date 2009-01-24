require File.expand_path(File.join(File.dirname(__FILE__), %w[.. .. test_helper])) unless defined?(Juicer)

class TestYuiCompressor < Test::Unit::TestCase

  def setup
    @path = ENV.key?('YUI_HOME') ? ENV['YUI_HOME'] : File.expand_path('~/sources/yuicompressor-2.3.5/build')

    @yui_compressor = Juicer::Minifyer::YuiCompressor.new({ :bin_path => @path })
    Juicer::Test::FileSetup.new.create
    @file = path('out.min.css')
  end

  def teardown
   File.delete(@file) if @file && File.exists?(@file)
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

  def test_locate_jar_no_existing_jar
    Juicer::Minifyer::YuiCompressor.publicize_methods do
      # Avoid developer env settings
      yuic_home = ENV['YUIC_HOME']
      ENV.delete('YUIC_HOME')

      assert_nil @yui_compressor.locate_jar

      # Reset developer env settings
      ENV['YUIC_HOME'] = yuic_home
    end
  end

  def test_locate_jar_one_file_in_cwd
    Juicer::Minifyer::YuiCompressor.publicize_methods do
      # Avoid developer env settings
      yuic_home = ENV['YUIC_HOME']
      ENV.delete('YUIC_HOME')

      File.open('yuicompressor-2.3.4.jar', 'w') { |f| f.puts '' }
      assert_equal File.expand_path('yuicompressor-2.3.4.jar'), @yui_compressor.locate_jar

      # Cleanup
      File.delete('yuicompressor-2.3.4.jar')

      # Reset developer env settings
      ENV['YUIC_HOME'] = yuic_home
    end
  end

  def test_locate_jar_two_files_in_cwd
    Juicer::Minifyer::YuiCompressor.publicize_methods do
      # Avoid developer env settings
      yuic_home = ENV['YUIC_HOME']
      ENV.delete('YUIC_HOME')

      # Create files
      File.open('yuicompressor-2.3.4.jar', 'w') { |f| f.puts '' }
      File.open('yuicompressor-2.3.5.jar', 'w') { |f| f.puts '' }

      # Test
      assert_equal File.expand_path('yuicompressor-2.3.5.jar'), @yui_compressor.locate_jar

      # Cleanup
      File.delete('yuicompressor-2.3.4.jar')
      File.delete('yuicompressor-2.3.5.jar')

      # Reset developer env settings
      ENV['YUIC_HOME'] = yuic_home
    end
  end

  def test_locate_jar_three_files_in_cwd
    Juicer::Minifyer::YuiCompressor.publicize_methods do
      # Avoid developer env settings
      yuic_home = ENV['YUIC_HOME']
      ENV.delete('YUIC_HOME')

      # Create files
      File.open('yuicompressor-2.3.4.jar', 'w') { |f| f.puts '' }
      File.open('yuicompressor-2.3.5.jar', 'w') { |f| f.puts '' }
      File.open('yuicompressor.jar', 'w') { |f| f.puts '' }

      # Test
      assert_equal File.expand_path('yuicompressor.jar'), @yui_compressor.locate_jar

      # Cleanup
      File.delete('yuicompressor-2.3.4.jar')
      File.delete('yuicompressor-2.3.5.jar')
      File.delete('yuicompressor.jar')

      # Reset developer env settings
      ENV['YUIC_HOME'] = yuic_home
    end
  end

  def test_locate_jar_custom_directory
    Juicer::Minifyer::YuiCompressor.publicize_methods do
      # Avoid developer env settings
      yuic_home = ENV['YUIC_HOME']
      ENV.delete('YUIC_HOME')

      # Prepare
      Dir.mkdir('another')
      Dir.chdir('another')
      File.open('yuicompressor-2.3.4.jar', 'w')
      Dir.chdir('..')

      # Test
      assert_nil @yui_compressor.locate_jar
      @yui_compressor = Juicer::Minifyer::YuiCompressor.new({ :bin_path => 'another' })
      assert_equal File.expand_path('another/yuicompressor-2.3.4.jar'), @yui_compressor.locate_jar

      # Clean up
      FileUtils.rm_rf("another")

      # Reset developer env settings
      ENV['YUIC_HOME'] = yuic_home
    end
  end
end
