# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{juicer}
  s.version = "0.2.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Christian Johansen"]
  s.date = %q{2009-04-29}
  s.default_executable = %q{juicer}
  s.description = %q{Juicer is a command line tool that helps you ship frontend code for production.  High level overview; Juicer can  * figure out which files depend on each other and merge them together, reducing the number of http requests per page view, thus improving performance * use YUI Compressor to compress code, thus improving performance * verify that your JavaScript is safe to minify/compress by running JsLint on it * cycle asset hosts in CSS files * add "cache busters" to URLs in CSS files * recalculate relative URLs in CSS files, as well as convert them to absolute (or convert absolute URLs to relative URLs)}
  s.email = %q{christian@cjohansen.no}
  s.executables = ["juicer"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "Readme.rdoc", "bin/juicer"]
  s.files = ["History.txt", "Manifest.txt", "Rakefile", "Readme.rdoc", "bin/juicer", "lib/juicer.rb", "lib/juicer/binary.rb", "lib/juicer/cache_buster.rb", "lib/juicer/chainable.rb", "lib/juicer/cli.rb", "lib/juicer/command/install.rb", "lib/juicer/command/list.rb", "lib/juicer/command/merge.rb", "lib/juicer/command/util.rb", "lib/juicer/command/verify.rb", "lib/juicer/core.rb", "lib/juicer/css_cache_buster.rb", "lib/juicer/install/base.rb", "lib/juicer/install/jslint_installer.rb", "lib/juicer/install/rhino_installer.rb", "lib/juicer/install/yui_compressor_installer.rb", "lib/juicer/jslint.rb", "lib/juicer/merger/base.rb", "lib/juicer/merger/css_dependency_resolver.rb", "lib/juicer/merger/dependency_resolver.rb", "lib/juicer/merger/javascript_dependency_resolver.rb", "lib/juicer/merger/javascript_merger.rb", "lib/juicer/merger/stylesheet_merger.rb", "lib/juicer/minifyer/yui_compressor.rb", "tasks/test/setup.rake", "test/juicer/command/test_install.rb", "test/juicer/command/test_list.rb", "test/juicer/command/test_merge.rb", "test/juicer/command/test_util.rb", "test/juicer/command/test_verify.rb", "test/juicer/install/test_installer_base.rb", "test/juicer/install/test_jslint_installer.rb", "test/juicer/install/test_rhino_installer.rb", "test/juicer/install/test_yui_compressor_installer.rb", "test/juicer/merger/test_base.rb", "test/juicer/merger/test_css_dependency_resolver.rb", "test/juicer/merger/test_javascript_dependency_resolver.rb", "test/juicer/merger/test_javascript_merger.rb", "test/juicer/merger/test_stylesheet_merger.rb", "test/juicer/minifyer/test_yui_compressor.rb", "test/juicer/test_cache_buster.rb", "test/juicer/test_chainable.rb", "test/juicer/test_core.rb", "test/juicer/test_css_cache_buster.rb", "test/juicer/test_jslint.rb", "test/test_helper.rb", "test/test_juicer.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://www.cjohansen.no/en/projects/juicer}
  s.post_install_message = %q{Juicer does not ship with third party libraries. You probably want to install
Yui Compressor and JsLint now:

juicer install yui_compressor
juicer install jslint

Happy juicing!
}
  s.rdoc_options = ["--main", "Readme.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{juicer}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Juicer is a command line tool that helps you ship frontend code for production}
  s.test_files = ["test/test_helper.rb", "test/juicer/test_cache_buster.rb", "test/juicer/test_chainable.rb", "test/juicer/test_jslint.rb", "test/juicer/install/test_installer_base.rb", "test/juicer/install/test_jslint_installer.rb", "test/juicer/install/test_yui_compressor_installer.rb", "test/juicer/install/test_rhino_installer.rb", "test/juicer/test_css_cache_buster.rb", "test/juicer/merger/test_javascript_dependency_resolver.rb", "test/juicer/merger/test_css_dependency_resolver.rb", "test/juicer/merger/test_base.rb", "test/juicer/merger/test_javascript_merger.rb", "test/juicer/merger/test_stylesheet_merger.rb", "test/juicer/command/test_verify.rb", "test/juicer/command/test_util.rb", "test/juicer/command/test_install.rb", "test/juicer/command/test_merge.rb", "test/juicer/command/test_list.rb", "test/juicer/test_core.rb", "test/juicer/minifyer/test_yui_compressor.rb", "test/test_juicer.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<cmdparse>, [">= 2.0.2"])
      s.add_runtime_dependency(%q<hpricot>, [">= 0.6.164"])
      s.add_runtime_dependency(%q<rubyzip>, [">= 0.9.1"])
      s.add_development_dependency(%q<bones>, [">= 2.4.0"])
    else
      s.add_dependency(%q<cmdparse>, [">= 2.0.2"])
      s.add_dependency(%q<hpricot>, [">= 0.6.164"])
      s.add_dependency(%q<rubyzip>, [">= 0.9.1"])
      s.add_dependency(%q<bones>, [">= 2.4.0"])
    end
  else
    s.add_dependency(%q<cmdparse>, [">= 2.0.2"])
    s.add_dependency(%q<hpricot>, [">= 0.6.164"])
    s.add_dependency(%q<rubyzip>, [">= 0.9.1"])
    s.add_dependency(%q<bones>, [">= 2.4.0"])
  end
end
