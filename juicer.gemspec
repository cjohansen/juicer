Gem::Specification.new do |s|
  s.name = %q{juicer}
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Christian Johansen"]
  s.date = %q{2009-01-04}
  s.default_executable = %q{juicer}
  s.description = %q{Juicer is a command line tool aimed at easing JavaScript and CSS development. Currently it only provides a wrapper to YUI Compressor along with a module that can dynamically link together files, but there are plans for more functionality.}
  s.email = %q{christian@cjohansen.no}
  s.executables = ["juicer"]
  s.extra_rdoc_files = ["History.txt", "Readme.rdoc", "bin/juicer", "test/data/Changelog.txt", "test/data/version-test.txt", "test/data/version.txt", "test/data/version2.txt"]
  s.files = [".gitignore", "History.txt", "Manifest.txt", "Rakefile", "Readme.rdoc", "bin/juicer", "juicer.gemspec", "lib/juicer.rb", "lib/juicer/chainable.rb", "lib/juicer/cli.rb", "lib/juicer/command/merge.rb", "lib/juicer/merger/base.rb", "lib/juicer/merger/css_dependency_resolver.rb", "lib/juicer/merger/dependency_resolver.rb", "lib/juicer/merger/javascript_dependency_resolver.rb", "lib/juicer/merger/javascript_merger.rb", "lib/juicer/merger/stylesheet_merger.rb", "lib/juicer/minifyer/compressor.rb", "lib/juicer/minifyer/yui_compressor.rb", "test/data/Changelog.txt", "test/data/a.css", "test/data/a.js", "test/data/b.css", "test/data/b.js", "test/data/mappe/a.css", "test/data/mappe/c.css", "test/data/mappe/enda_en_mappe/a.css", "test/data/version-test.txt", "test/data/version.txt", "test/data/version2.txt", "test/juicer/merger/test_base.rb", "test/juicer/merger/test_css_dependency_resolver.rb", "test/juicer/merger/test_javascript_dependency_resolver.rb", "test/juicer/merger/test_javascript_merger.rb", "test/juicer/merger/test_stylesheet_merger.rb", "test/juicer/minifyer/test_compressor.rb", "test/juicer/minifyer/test_yui_compressor.rb", "test/juicer/test_chainable.rb", "test/test_helper.rb", "test/test_juicer.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://www.cjohansen.no/en/projects/juicer}
  s.rdoc_options = ["--main", "Readme.rdoc"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{juicer}
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{Juicer is a command line tool aimed at easing JavaScript and CSS development}
  s.test_files = ["test/test_helper.rb", "test/juicer/test_chainable.rb", "test/juicer/merger/test_javascript_dependency_resolver.rb", "test/juicer/merger/test_css_dependency_resolver.rb", "test/juicer/merger/test_base.rb", "test/juicer/merger/test_javascript_merger.rb", "test/juicer/merger/test_stylesheet_merger.rb", "test/juicer/minifyer/test_compressor.rb", "test/juicer/minifyer/test_yui_compressor.rb", "test/test_juicer.rb"]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_runtime_dependency(%q<cmdparse>, [">= 2.0.2"])
      s.add_development_dependency(%q<bones>, [">= 2.2.0"])
    else
      s.add_dependency(%q<cmdparse>, [">= 2.0.2"])
      s.add_dependency(%q<bones>, [">= 2.2.0"])
    end
  else
    s.add_dependency(%q<cmdparse>, [">= 2.0.2"])
    s.add_dependency(%q<bones>, [">= 2.2.0"])
  end
end
