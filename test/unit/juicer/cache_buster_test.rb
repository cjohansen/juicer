# -*- coding: utf-8 -*-

require "test_helper"
require "juicer/cache_buster"

class CacheBusterTest < Test::Unit::TestCase
  def setup
    @filename = "tmp.cachebuster.txt"
    File.open(@filename, "w") { |f| f.puts "Testing" }
  end

  def teardown
    File.delete(@filename)
  end

  context "cleaning files with cache busters" do
    should "remove cache buster query parameters" do
      assert_equal @filename, Juicer::CacheBuster.clean("#@filename?jcb=1234567890")
    end

    should "remove cache buster query parameters, but preserve other query parameters" do
      assert_equal "#@filename?some=param&others=again", Juicer::CacheBuster.clean("#@filename?some=param&jcb=1234567890&others=again")
    end

    should "remove cache buster query parameters with no name" do
      assert_equal @filename, Juicer::CacheBuster.clean("#@filename?1234567890", nil)
    end

    should "not destroy numeric file names with no cache buster name" do
      @numeric_filename = "815.gif"
      File.open(@numeric_filename, "w") { |f| f.puts "Testing" }
      assert_equal @numeric_filename, Juicer::CacheBuster.clean("#@numeric_filename?1234567890", nil)
      File.delete(@numeric_filename)
    end

    should "remove cache buster query parameters with custom name" do
      assert_equal @filename, Juicer::CacheBuster.clean("#@filename?cb=1234567890", :cb)
    end
    
    should "remove hard cache buster" do
      assert_equal @filename, Juicer::CacheBuster.clean(@filename.sub(/(\.txt)/, '-jcb1234567890\1'))
    end

    should "remove hard cache buster and preserve query params" do
      assert_equal "#@filename?hey=there", Juicer::CacheBuster.clean("#@filename?hey=there".sub(/(\.txt)/, '-jcb1234567890\1'))
    end
  end

  context "creating soft cache busters" do
    should "clean file before adding new cache buster" do
      cache_buster = "jcb=1234567890"
      assert_no_match /#{cache_buster}/, Juicer::CacheBuster.soft("#@filename?#{cache_buster}")
    end

    should "preserve query parameters" do
      parameters = "id=1"
      assert_match /#{parameters}/, Juicer::CacheBuster.soft("#@filename?#{parameters}")
    end

    should "raise error if file is not found" do
      assert_raise ArgumentError do
        Juicer::CacheBuster.path("#@filename.ico")
      end
    end

    should "include mtime as query parameter" do
      mtime = File.mtime(@filename).to_i
      assert_equal "#@filename?jcb=#{mtime}", Juicer::CacheBuster.soft(@filename)
    end

    should "include only mtime when parameter name is nil" do
      mtime = File.mtime(@filename).to_i
      assert_equal "#@filename?#{mtime}", Juicer::CacheBuster.soft(@filename, nil)
    end

    should "include custom parameter name" do
      mtime = File.mtime(@filename).to_i
      assert_equal "#@filename?juicer=#{mtime}", Juicer::CacheBuster.soft(@filename, :juicer)
    end
  end

  context "creating rails-style cache busters" do
    should "clean file before adding new cache buster" do
      cache_buster = "1234567890"
      assert_no_match /#{cache_buster}/, Juicer::CacheBuster.rails("#@filename?#{cache_buster}")
    end

    should "append no cache buster when parameters exist" do
      parameters = "id=1"
      assert_match /#{parameters}/, Juicer::CacheBuster.rails("#@filename?#{parameters}")
    end

    should "include only mtime as query parameter" do
      mtime = File.mtime(@filename).to_i
      assert_equal "#@filename?#{mtime}", Juicer::CacheBuster.rails(@filename)
    end
  end

  context "hard cache busters" do
    setup { @filename.sub!(/\.txt/, '') }
    teardown { @filename = "#@filename.txt" }

    should "clean file before adding new cache buster" do
      cache_buster = "-jcb1234567890"
      assert_no_match /#{cache_buster}/, Juicer::CacheBuster.hard("#@filename#{cache_buster}.txt")
    end

    should "preserve query parameters" do
      parameters = "id=1"
      assert_match /#{parameters}/, Juicer::CacheBuster.hard("#@filename.txt?#{parameters}")
    end

    should "include mtime in filename" do
      mtime = File.mtime("#@filename.txt").to_i
      assert_equal "#@filename-jcb#{mtime}.txt", Juicer::CacheBuster.hard("#@filename.txt")
    end

    should "include only mtime when parameter name is nil" do
      mtime = File.mtime("#@filename.txt").to_i
      assert_equal "#@filename-#{mtime}.txt", Juicer::CacheBuster.hard("#@filename.txt", nil)
    end

    should "include custom parameter name" do
      mtime = File.mtime("#@filename.txt").to_i
      assert_equal "#@filename-juicer#{mtime}.txt", Juicer::CacheBuster.hard("#@filename.txt", :juicer)
    end
  end
end
