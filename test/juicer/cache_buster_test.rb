require "test_helper"

class TestCacheBuster < Test::Unit::TestCase
  def setup
    Juicer::Test::FileSetup.new.create
  end

  context "cache buster soft path" do
    should "use default param name" do
      file = path("a.js")
      mtime = File.new(file).mtime.to_i
      assert_equal "#{file}?jcb=#{mtime}", Juicer::CacheBuster.path(file)
    end

    should "use explicit soft type and default param name" do
      file = path("a.js")
      mtime = File.new(file).mtime.to_i
      assert_equal "#{file}?jcb=#{mtime}", Juicer::CacheBuster.path(file, :soft)
    end

    should "should use mtime param name" do
      file = path("a.js")
      mtime = File.new(file).mtime.to_i
      assert_equal "#{file}?mtime=#{mtime}", Juicer::CacheBuster.path(file, :soft, "mtime")
      assert_equal "#{file}?mtime=#{mtime}", Juicer::CacheBuster.path(file, :soft, :mtime)
    end

    should "use empty param name" do
      file = path("a.js")
      mtime = File.new(file).mtime.to_i
      assert_equal "#{file}?#{mtime}", Juicer::CacheBuster.path(file, :soft, nil)
      assert_equal "#{file}?#{mtime}", Juicer::CacheBuster.path(file, :soft, "")
    end
  end

  context "cache buster hard path" do
    should "use default param name" do
      file = path("a.js")
      mtime = File.new(file).mtime.to_i
      assert_equal "#{File.dirname(file)}/a-#{mtime}.js", Juicer::CacheBuster.path(file, :hard)
    end

    should "use empty param name" do
      file = path("a.js")
      mtime = File.new(file).mtime.to_i
      assert_equal "#{File.dirname(file)}/a-#{mtime}.js", Juicer::CacheBuster.path(file, :hard, "")
      assert_equal "#{File.dirname(file)}/a-#{mtime}.js", Juicer::CacheBuster.path(file, :hard, nil)
    end

    should "use param name" do
      file = path("a.js")
      mtime = File.new(file).mtime.to_i
      assert_equal "#{File.dirname(file)}/a-cb#{mtime}.js", Juicer::CacheBuster.path(file, :hard, "cb")
    end

    should "update soft path" do
      file = path("a.js")
      mtime = File.new(file).mtime.to_i
      assert_equal "#{File.dirname(file)}/a.js?cb=#{mtime}", Juicer::CacheBuster.path("#{file}?cb=1234", :soft, "cb")
    end
  end
end
