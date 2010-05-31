require "test_helper"
require "juicer/minifyer/closure_compiler"

class ClosureCompilerTest < Test::Unit::TestCase
  def setup
    @jar = "compiler.jar"
    @input = "in-file.css"
    @output = "out-file.css"
    @cmd = %Q{-jar "#@jar"}
    @closure = Juicer::Minifyer::ClosureCompiler.new
    @closure.stubs(:locate_jar).returns(@jar)
  end

  context "#save" do
    should "overwrite existing file" do
      @closure.expects(:execute).with(%Q{#@cmd --js_output_file "#@output" --js "#@output"})
      @closure.save(@output, @output)
    end

    should "write compressed input to output" do
      @closure.expects(:execute).with(%Q{#@cmd --js_output_file "#@output" --js "#@input"})
      @closure.save(@input, @output)
    end

    should "create non-existant path" do
      output = "some/nested/directory"
      @closure.expects(:execute).with(%Q{#@cmd --js_output_file "#{output}/file.css" --js "#@input"})
      FileUtils.expects(:mkdir_p).with(output)
      @closure.save(@input, "#{output}/file.css")
    end
  end

  context "locating jar" do
    setup do
      # Avoid developer env settings
      @closure_home = ENV['CLOSUREC_HOME']
      ENV.delete('CLOSUREC_HOME')
    end

    teardown do
      ENV['CLOSUREC_HOME'] = @closure_home
      File.delete('compiler-2.3.4.jar') if File.exists?('compiler-2.3.4.jar')
      File.delete('compiler-2.3.5.jar') if File.exists?('compiler-2.3.5.jar')
      File.delete('compiler.jar') if File.exists?('compiler.jar')
      FileUtils.rm_rf("another") if File.exists?("another")
    end
    
    should "not find jar when no jars on path" do
      Juicer::Minifyer::ClosureCompiler.publicize_methods do
        closure = Juicer::Minifyer::ClosureCompiler.new

        assert_nil closure.locate_jar
      end
    end

    should "find only jar in path" do
      Juicer::Minifyer::ClosureCompiler.publicize_methods do
        File.open('compiler-2.3.4.jar', 'w') { |f| f.puts '' }
        closure = Juicer::Minifyer::ClosureCompiler.new

        assert_equal File.expand_path('compiler-2.3.4.jar'), closure.locate_jar
      end
    end

    should "find most recent of two jars on path" do
      Juicer::Minifyer::ClosureCompiler.publicize_methods do
        # Create files
        File.open('compiler-2.3.4.jar', 'w') { |f| f.puts '' }
        File.open('compiler-2.3.5.jar', 'w') { |f| f.puts '' }

        closure = Juicer::Minifyer::ClosureCompiler.new
        
        # Test
        assert_equal File.expand_path('compiler-2.3.5.jar'), closure.locate_jar
      end
    end

    should "find most recent of three jar files on path" do
      Juicer::Minifyer::ClosureCompiler.publicize_methods do
        # Create files
        File.open('compiler-2.3.4.jar', 'w') { |f| f.puts '' }
        File.open('compiler-2.3.5.jar', 'w') { |f| f.puts '' }
        File.open('compiler.jar', 'w') { |f| f.puts '' }

        closure = Juicer::Minifyer::ClosureCompiler.new
        
        # Test
        assert_equal File.expand_path('compiler.jar'), closure.locate_jar
      end
    end

    should "find jar in custom directory" do
      Juicer::Minifyer::ClosureCompiler.publicize_methods do
        # Prepare
        Dir.mkdir('another')
        File.open('another/compiler-2.3.4.jar', 'w') { |f| f.puts "" }

        closure = Juicer::Minifyer::ClosureCompiler.new
        
        # Test
        assert_nil closure.locate_jar
        closure = Juicer::Minifyer::ClosureCompiler.new({ :bin_path => 'another' })
        assert_equal File.expand_path('another/compiler-2.3.4.jar'), closure.locate_jar
      end
    end
  end
end
