require 'fileutils'
require 'open-uri'

namespace :test do
  desc "Download third party libraries needed to successfully run tests"
  task :setup do
    download("http://www.julienlecomte.net/yuicompressor/yuicompressor-2.4.2.zip")
    download("http://www.jslint.com/rhino/jslint.js")
    download("ftp://ftp.mozilla.org/pub/mozilla.org/js/rhino1_7R1.zip")
    download("http://www.julienlecomte.net/yuicompressor/")
  end
end

def download(url)
  filename = File.join(File.dirname(__FILE__), "../../test/bin", File.basename(url))
  return filename if File.exists?(filename)

  puts "Downloading #{url} to #{filename}"
  FileUtils.mkdir_p(File.dirname(filename))

  File.open(filename, "wb") do |file|
    webpage = open(url)
    file.write(webpage.read)
    webpage.close
  end

  filename
end
