require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "juicer"
    gem.summary = "Command line tool for CSS and JavaScript developers"
    gem.description = "Resolve dependencies, merge and minify CSS and JavaScript files with Juicer - the command line tool for frontend engineers"
    gem.email = "christian@cjohansen.no"
    gem.homepage = "http://github.com/cjohansen/juicer"
    gem.authors = ["Christian Johansen"]
    gem.rubyforge_project = "juicer"
    gem.add_development_dependency "shoulda", ">= 2.10.2"
    gem.add_development_dependency "mocha", ">= 0.9.8"
    gem.add_development_dependency "fakefs", ">= 0.2.1"
    gem.add_development_dependency "jeweler", ">= 0.2.1"
    gem.add_development_dependency "redgreen", ">= 1.2.2" if RUBY_VERSION < "1.9"
    gem.add_dependency "cmdparse"
    gem.add_dependency "nokogiri"
    gem.add_dependency "rubyzip"
    gem.executables = ["juicer"]
    gem.post_install_message = <<-MSG
Juicer does not ship with third party libraries. You probably want to install
Yui Compressor and JsLint now:

juicer install yui_compressor
juicer install jslint

Happy juicing!
    MSG
    gem.files = FileList["[A-Z]*", "{bin,generators,lib,test}/**/*"]
  end

  Jeweler::GemcutterTasks.new
  Jeweler::RubyforgeTasks.new do |rubyforge|
    rubyforge.doc_task = "rdoc"
  end
rescue LoadError => err
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
  puts err.message
end

Rake::TestTask.new("test:units") do |test|
  test.libs << 'test'
  test.pattern = 'test/unit/**/*_test.rb'
  test.verbose = true
end

Rake::TestTask.new("test:integration") do |test|
  test.libs << 'test'
  test.pattern = 'test/integration/**/*_test.rb'
  test.verbose = true
end

task :test => ["check_dependencies:development", "test:units", "test:integration"]

task :default => "test:units"

# lib/tasks/cruise.rake
desc 'Continuous build target'
task :cruise do
  out = ENV['CC_BUILD_ARTIFACTS']
  mkdir_p out unless File.directory? out if out
 
  Rake::Task["rcov"].invoke
  mv 'coverage/', "#{out}/" if out
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/*_test.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "jstdutil #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
