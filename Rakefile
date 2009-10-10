# Look in the tasks/setup.rb file for the various options that can be
# configured in this Rakefile. The .rake files in the tasks directory
# are where the options are used.

# begin
#   require 'bones'
#   Bones.setup
# rescue LoadError
#   begin
#     load 'tasks/setup.rb'
#   rescue LoadError
#     raise RuntimeError, '### please install the "bones" gem ###'
#   end
# end

# ensure_in_path 'lib'
# require 'juicer'

# task :default => 'test:run'

# PROJ.name = 'juicer'
# PROJ.authors = 'Christian Johansen'
# PROJ.email = 'christian@cjohansen.no'
# PROJ.url = 'http://www.cjohansen.no/en/projects/juicer'
# PROJ.version = Juicer::VERSION
# PROJ.rubyforge.name = 'juicer'
# PROJ.readme_file = 'Readme.rdoc'
# PROJ.exclude = %w(tmp$ bak$ ~$ CVS \.svn ^pkg ^doc \.git ^rcov ^test\/data gemspec ^test\/bin)
# PROJ.rdoc.remote_dir = 'juicer'

# PROJ.spec.opts << '--color'

# PROJ.gem.extras[:post_install_message] = <<-MSG
# Juicer does not ship with third party libraries. You probably want to install
# Yui Compressor and JsLint now:

# juicer install yui_compressor
# juicer install jslint

# Happy juicing!
# MSG

# CLOBBER.include "test/data"

# depend_on 'cmdparse'
# depend_on 'nokogiri'
# depend_on 'rubyzip'

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'test'
  test.pattern = 'test/**/*_test.rb'
  test.verbose = true
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

task :default => :test
