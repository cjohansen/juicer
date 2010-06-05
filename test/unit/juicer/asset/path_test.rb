# -*- coding: utf-8 -*-

require "test_helper"
require "juicer/asset/path"

class AssetPathTest < Test::Unit::TestCase
  context "initializing asset" do
    should "use default options" do
      asset = Juicer::Asset::Path.new "../images/logo.png"

      assert_equal Dir.pwd, asset.base
      assert_equal [], asset.hosts
      assert_nil asset.document_root
    end

    should "override options" do
      base = "/home/me/project/awesome-site/public/stylesheets"
      asset = Juicer::Asset::Path.new "../images/logo.png", :base => base

      assert_equal base, asset.base
    end

    should "not nil base option" do
      asset = Juicer::Asset::Path.new "../images/logo.png", :base => nil

      assert_equal Dir.pwd, asset.base
    end

    should "accept a single host" do
      asset = Juicer::Asset::Path.new "../images/logo.png", :hosts => "http://localhost"

      assert_equal ["http://localhost"], asset.hosts
    end

    should "accept array of hosts" do
      asset = Juicer::Asset::Path.new "../images/logo.png", :hosts => ["http://localhost", "http://dev.server"]

      assert_equal ["http://localhost", "http://dev.server"], asset.hosts
    end

    should "strip trailing slash in hosts" do
      asset = Juicer::Asset::Path.new "../images/logo.png", :hosts => ["http://localhost/", "http://dev.server"]

      assert_equal ["http://localhost", "http://dev.server"], asset.hosts
    end

    should "strip add scheme for hosts if missing" do
      asset = Juicer::Asset::Path.new "../images/logo.png", :hosts => ["localhost", "http://dev.server"]

      assert_equal ["http://localhost", "http://dev.server"], asset.hosts
    end

    should "strip trailing slash and add scheme in hosts" do
      asset = Juicer::Asset::Path.new "../images/logo.png", :hosts => ["localhost/", "http://dev.server", "some.server/"]

      assert_equal ["http://localhost", "http://dev.server", "http://some.server"], asset.hosts
    end

    should "accept protocol-less hosts" do
      asset = Juicer::Asset::Path.new "../images/logo.png", :hosts => ["localhost/", "//dev.server", "some.server/"]

      assert_equal ["http://localhost", "//dev.server", "http://some.server"], asset.hosts
    end
  end

  context "asset absolute path" do
    should "raise exception without document root" do
      asset = Juicer::Asset::Path.new "../images/logo.png"

      assert_raise ArgumentError do
        asset.absolute_path
      end
    end

    should "return absolute path from relative path and document root" do
      base = "/var/www/public/stylesheets"
      document_root = "/var/www/public"
      asset = Juicer::Asset::Path.new "../images/logo.png", :base => base, :document_root => document_root

      assert_equal "/images/logo.png", asset.absolute_path
    end

    should "return absolute path from absolute path" do
      base = "/var/www/public/stylesheets"
      document_root = "/var/www/public"
      path = "/images/logo.png"
      asset = Juicer::Asset::Path.new path, { :base => base, :document_root => document_root }

      assert_equal path, asset.absolute_path
    end

    context "with host" do
      setup do
        base = "/var/www/public/stylesheets"
        document_root = "/var/www/public"
        options = { :base => base, :document_root => document_root }
        @asset = Juicer::Asset::Path.new "../images/logo.png", options
      end

      should "return absolute path with host" do
        assert_equal "http://localhost/images/logo.png", @asset.absolute_path(:host => "http://localhost")
      end

      should "strip trailing slash from absolute path host" do
        assert_equal "http://localhost/images/logo.png", @asset.absolute_path(:host => "http://localhost/")
      end

      should "ensure scheme in absolute path host" do
        assert_equal "http://localhost/images/logo.png", @asset.absolute_path(:host => "localhost")
      end

      should "strip trailing slash and ensure scheme in absolute path host" do
        assert_equal "http://localhost/images/logo.png", @asset.absolute_path(:host => "localhost/")
      end
    end

    context "with cache buster" do
      setup do
        @filename = "tmp.asset.txt"
        file = File.open(@filename, "w") { |f| f.puts "Testing" }
        @asset = Juicer::Asset::Path.new @filename, :document_root => Dir.pwd
      end

      teardown do
        File.delete(@filename)
      end

      should "return URL with mtime query parameter and default parameter name" do
        mtime = File.mtime(@filename).to_i
        assert_equal "/#@filename?jcb=#{mtime}", @asset.absolute_path(:cache_buster_type => :soft)
      end

      should "return URL with mtime query parameter" do
        mtime = File.mtime(@filename).to_i
        assert_equal "/#@filename?#{mtime}", @asset.absolute_path(:cache_buster => nil)
      end

      should "return URL with mtime embedded" do
        mtime = File.mtime(@filename).to_i
        assert_equal "/#{@filename.sub(/\.txt/, '')}-jcb#{mtime}.txt", @asset.absolute_path(:cache_buster => :jcb, :cache_buster_type => :hard)
      end
    end
  end

  context "relative path" do
    should "return relative path from relative path" do
      path = "../images/logo.png"
      asset = Juicer::Asset::Path.new path, :base => "/var/www/public/stylesheets"

      assert_equal path, asset.relative_path
    end

    should "return relative path from absolute path" do
      path = "/images/logo.png"
      asset = Juicer::Asset::Path.new path, :document_root => "/var/www/public", :base => "/var/www/public/stylesheets"

      assert_equal "..#{path}", asset.relative_path
    end

    context "with cache buster" do
      setup do
        @filename = "tmp.asset.txt"
        file = File.open(@filename, "w") { |f| f.puts "Testing" }
        @asset = Juicer::Asset::Path.new @filename, :document_root => Dir.pwd
      end

      teardown do
        File.delete(@filename)
      end

      should "return URL with mtime query parameter and default parameter name" do
        mtime = File.mtime(@filename).to_i
        result = "#@filename?jcb=#{mtime}"
        Juicer::CacheBuster.stubs(:soft).with(File.expand_path(@filename)).returns(result)

        assert_equal result, @asset.relative_path(:cache_buster_type => :soft)
      end

      should "return URL with mtime query parameter" do
        mtime = File.mtime(@filename).to_i
        assert_equal "#@filename?#{mtime}", @asset.relative_path(:cache_buster => nil)
      end

      should "return URL with mtime embedded" do
        mtime = File.mtime(@filename).to_i
        assert_equal "#{@filename.sub(/\.txt/, '')}-jcb#{mtime}.txt", @asset.relative_path(:cache_buster => :jcb, :cache_buster_type => :hard)
      end
    end
  end

  context "original path" do
    should "preserve relative path" do
      path = "../images/logo.png"
      asset = Juicer::Asset::Path.new path

      assert_equal path, asset.path
    end

    should "preserve absolute path" do
      path = "/images/logo.png"
      asset = Juicer::Asset::Path.new path

      assert_equal path, asset.path
    end

    should "preserve absolute path with host" do
      path = "http://localhost/images/logo.png"
      asset = Juicer::Asset::Path.new path

      assert_equal path, asset.path
    end

    context "with cache buster" do
      setup do
        @filename = "tmp.asset.txt"
        file = File.open(@filename, "w") { |f| f.puts "Testing" }
      end

      teardown do
        File.delete(@filename)
      end

      should "return original relative path with mtime query parameter and default parameter name" do
        asset = Juicer::Asset::Path.new @filename, :document_root => Dir.pwd
        mtime = File.mtime(@filename).to_i
        assert_equal "#@filename?jcb=#{mtime}", asset.path(:cache_buster_type => :soft)
      end

      should "return original absolute path with mtime query parameter and default parameter name" do
        asset = Juicer::Asset::Path.new "/#@filename", :document_root => Dir.pwd
        mtime = File.mtime(@filename).to_i
        assert_equal "/#@filename?jcb=#{mtime}", asset.path(:cache_buster_type => :soft)
      end
    end
  end

  context "asset filename" do
    should "raise exception with absolute path without document root" do
      asset = Juicer::Asset::Path.new "/images/logo.png", :document_root => nil

      assert_raise ArgumentError do
        asset.filename
      end
    end

    should "raise exception with absolute path with host without document root" do
      asset = Juicer::Asset::Path.new "http://localhost/images/logo.png", :document_root => nil

      assert_raise ArgumentError do
        asset.filename
      end
    end

    should "raise exception with absolute path with host without hosts" do
      options = { :document_root => "/var/project" }
      asset = Juicer::Asset::Path.new "http://localhost/images/logo.png", options

      assert_raise ArgumentError do
        begin
          asset.filename
        rescue ArgumentError => err
          assert_match /No hosts served/, err.message
          raise err
        end
      end
    end

    should "raise exception with mismatching hosts" do
      options = { :document_root => "/var/project", :hosts => %w[example.com site.com] }
      asset = Juicer::Asset::Path.new "http://localhost/images/logo.png", options

      assert_raise ArgumentError do
        begin
          asset.filename
        rescue ArgumentError => err
          assert_match /No matching host/, err.message
          raise err
        end
      end
    end

    should "return filename from relative path and base" do
      asset = Juicer::Asset::Path.new "../images/logo.png", :base => "/var/www/public/stylesheets"

      assert_equal "/var/www/public/images/logo.png", asset.filename
    end

    should "return filename from absolute path and document root" do
      asset = Juicer::Asset::Path.new "/images/logo.png", :document_root => "/var/www/public"

      assert_equal "/var/www/public/images/logo.png", asset.filename
    end

    should "return filename from absolute path with host and document root" do
      asset = Juicer::Asset::Path.new "http://localhost/images/logo.png", :document_root => "/var/www/public", :hosts => "localhost"

      assert_equal "/var/www/public/images/logo.png", asset.filename
    end

    should "raise exception when hosts match but schemes don't" do
      options = { :document_root => "/var/www/public", :hosts => "http://localhost" }
      asset = Juicer::Asset::Path.new "https://localhost/images/logo.png", options

      assert_raise(ArgumentError) { asset.filename }
    end

    should "return filename from absolute path with hosts and document root" do
      options = { :document_root => "/var/www/public", :hosts => %w[example.com localhost https://localhost] }
      asset = Juicer::Asset::Path.new "https://localhost/images/logo.png", options

      assert_equal "/var/www/public/images/logo.png", asset.filename
    end
  end

  context "file helpers" do
    should "return file basename" do
      base = "/var/www/public/"
      asset = Juicer::Asset::Path.new "images/logo.png", :base => base

      assert_equal "logo.png", asset.basename
    end

    should "return file dirname" do
      base = "/var/www/public/"
      asset = Juicer::Asset::Path.new "images/logo.png", :base => base

      assert_equal "#{base}images", asset.dirname
    end

    should "verify that file does not exist" do
      base = "/var/www/public/"
      asset = Juicer::Asset::Path.new "images/logo.png", :base => base

      assert !asset.exists?
    end

    context "existing file" do
      setup { File.open("somefile.css", "w") { |f| f.puts "/* Test */" } }
      teardown { File.delete("somefile.css") }

      should "verify that file exists" do
        asset = Juicer::Asset::Path.new "somefile.css"

        assert asset.exists?
      end
    end
  end

  context "rebase path" do
    should "return new asset with shifted base" do
      base = "/var/www/project/public"
      asset = Juicer::Asset::Path.new "../images/logo.png", :base => "#{base}/stylesheets"
      rebased_asset = asset.rebase(base)

      assert_equal "images/logo.png", rebased_asset.relative_path
    end

    should "preserve all options but base context" do
      base = "/var/www/project/public"
      options = { :base => "#{base}/stylesheets", :hosts => ["localhost"], :document_root => base }
      asset = Juicer::Asset::Path.new "../images/logo.png", options
      rebased_asset = asset.rebase(base)

      assert_equal asset.document_root, rebased_asset.document_root
      assert_equal asset.hosts, rebased_asset.hosts
    end

    should "return same absolute path" do
      base = "/var/www/project/public"
      asset = Juicer::Asset::Path.new "../images/logo.png", :base => "#{base}/stylesheets", :document_root => base
      rebased_asset = asset.rebase(base)

      assert_equal asset.absolute_path, rebased_asset.absolute_path
    end
  end
end
