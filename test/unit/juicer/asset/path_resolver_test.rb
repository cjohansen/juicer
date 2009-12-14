# -*- coding: utf-8 -*-

require "test_helper"
require "juicer/asset/path_resolver"

class AssetPathResolverTest < Test::Unit::TestCase
  context "initializing path resolver" do
    should "use current directory as base" do
      resolver = Juicer::Asset::PathResolver.new

      assert_equal Dir.pwd, resolver.base
    end

    should "ensure all hosts are complete with scheme" do
      resolver = Juicer::Asset::PathResolver.new :hosts => %w[localhost my.project]

      assert_equal %w[http://localhost http://my.project], resolver.hosts
    end

    should "set document root" do
      resolver = Juicer::Asset::PathResolver.new :document_root => Dir.pwd

      assert_equal Dir.pwd, resolver.document_root
    end
  end

  context "resolving path" do
    should "return asset object with the same options as the resolver" do
      resolver = Juicer::Asset::PathResolver.new :document_root => "/var/www", :hosts => ["localhost", "mysite.com"]
      asset = resolver.resolve("../images/logo.png")

      assert_equal resolver.base, asset.base
      assert_equal resolver.document_root, asset.document_root
      assert_equal resolver.hosts, asset.hosts
    end
  end

  context "cycling hosts" do
    should "return one host at a time" do
      resolver = Juicer::Asset::PathResolver.new :hosts => %w[localhost my.project]

      assert_equal "http://localhost", resolver.cycle_hosts
      assert_equal "http://my.project", resolver.cycle_hosts
      assert_equal "http://localhost", resolver.cycle_hosts
    end

    should "be aliased through host" do
      resolver = Juicer::Asset::PathResolver.new :hosts => %w[localhost my.project]

      assert_equal "http://localhost", resolver.host
      assert_equal "http://my.project", resolver.host
      assert_equal "http://localhost", resolver.host
    end
  end

  context "setting base" do
    should "update property" do
      resolver = Juicer::Asset::PathResolver.new
      new_base = "/var/www/test"
      resolver.base = new_base

      assert_equal new_base, resolver.base
    end

    should "update base option for new assets" do
      resolver = Juicer::Asset::PathResolver.new
      asset1 = resolver.resolve "css/1.css"
      resolver.base = "/var/www/test"
      asset2 = resolver.resolve "css/1.css"

      assert_not_equal asset1.base, asset2.base
      assert_not_equal asset1.base, resolver.base
      assert_equal asset2.base, resolver.base
    end
  end
end
