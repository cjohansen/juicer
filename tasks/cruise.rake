# lib/tasks/cruise.rake
desc 'Continuous build target'
task :cruise do
  out = ENV['CC_BUILD_ARTIFACTS']
  mkdir_p out unless File.directory? out if out
 
  ENV['SHOW_ONLY'] = 'models,lib,helpers'
  Rake::Task["test:rcov"].invoke
  mv 'coverage/', "#{out}/" if out
end