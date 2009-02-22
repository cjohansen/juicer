require 'fileutils'
require 'open-uri'

namespace :test do
  desc "Download third party libraries needed to successfully run tests"
  task :setup do
    root = File.join(File.dirname(__FILE__), "../../test/bin")
    yui242 = File.join(root, "yuicompressor-2.4.2.zip")
    jslint = File.join(root, "jslint.js")
    rhino = File.join(root, "rhino1_7R2-RC1.zip")

    download("http://www.julienlecomte.net/yuicompressor/yuicompressor-2.4.2.zip")
    FileUtils.cp(File.join(root, "yuicompressor-2.4.2.zip"), File.join(root, "yuicompressor-2.3.5.zip"))
    download("http://www.jslint.com/rhino/jslint.js")
    download("ftp://ftp.mozilla.org/pub/mozilla.org/js/rhino1_7R1.zip")
    download("ftp://ftp.mozilla.org/pub/mozilla.org/js/rhino1_7R2-RC1.zip")
    download("http://www.julienlecomte.net/yuicompressor/")
  end
end

def download(url)
  filename = File.expand_path(File.join(File.dirname(__FILE__), "../../test/bin", File.basename(url)))
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
