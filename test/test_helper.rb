require 'fileutils'
require 'test/unit'
require 'rubygems'
require File.expand_path(File.join(File.dirname(__FILE__), %w[.. lib juicer])) unless defined?(Juicer)

# Test directory
$TEST_DIR = File.expand_path(File.dirname(__FILE__))

# Directory containing test data
$DATA_DIR = File.join($TEST_DIR, 'data')

# Prefixes paths with the data dir
def path(path)
  File.join($DATA_DIR, path)
end

# Allow for testing of private methods inside a block:
#
#  MyClass.publicize_methods do
#    assert MyClass.some_private_method
#  end
class Class
  def publicize_methods
    saved_private_instance_methods = self.private_instance_methods
    self.class_eval { public(*saved_private_instance_methods) }
    yield
    self.class_eval { private(*saved_private_instance_methods) }
  end
end

module Juicer
  module Test

    # Alot of Juicer functionality are filesystem operations. This class sets up files
    # to work on
    class FileSetup
      attr_reader :file_count

      def initialize(dir = $DATA_DIR)
        @dir = dir
        @file_count = 0
      end

      # Recursively deletes the data directory
      def delete!
        res = FileUtils.remove_dir(@dir) if File.exist?(@dir)
      end

      # Set up files for unit tests
      def create!(force = false)
        return if File.exist?(@dir) && !force

        delete! if File.exist?(@dir)
        mkdir @dir

        # mappe/
        mappe = mkdir(File.join(@dir, 'mappe'))
        #mkfile(mappe, 'a.css', "@import 'b.css';\n\n/* Dette er a.css */")
        mkfile(mappe, 'a.css', "/**\n * Test with comment\n */\n@import 'b.css';\n\n/* Dette er a.css */\n")

        mkfile(mappe, 'c.css', "/* Dette er b.css */")

        # mappe/enda_en_mappe/
        enda_en_mappe = mkdir(File.join(@dir, 'mappe', 'enda_en_mappe'))
        mkfile(enda_en_mappe, 'a.css', "@import 'b.css';\n\n/* Dette er a.css */\n")
        mksvndir(enda_en_mappe)

        # Filer
        mkfile(@dir, 'a.css', "@import 'b.css';\n\n/* Dette er a.css */")
        mkfile(@dir, 'a.js', "/**\n * @depend b.js\n */\n\n/* Dette er a.js */")
        mkfile(@dir, 'b.css', "/* Dette er b.css */")
        mkfile(@dir, 'b.js', "/**\n * @depends a.js\n */\n\n/* Dette er b.css */")
        mkfile(@dir, 'a1.css', "@charset = 'UTF-8';\n@import 'b1.css';\n@import 'c1.css';\nbody {\n    width: 800px;\n}\n")
        mkfile(@dir, 'b1.css', "@charset = 'UTF-8';\n@import 'd1.css';\n\nhtml {\n    background: red;\n}\n")
        mkfile(@dir, 'c1.css', "@charset = 'UTF-8';\nh1 {\n    font-size: 12px;\n}\n")
        mkfile(@dir, 'd1.css', "@charset = 'UTF-8';\nh2 {\n    font-size: 10px;\n}\n")
        mkfile(@dir, 'Changelog.txt', "2008.02.09 | stb-base 1.29\n\nFEATURE: Core  | Bla bla bla bla bla\nFEATURE: UI: | Bla bla bla bla bla\n\n\n2008.02.09 | stb-base 1.29\n\nFEATURE: Core  | Bla bla bla bla bla\nFEATURE: UI: | Bla bla bla bla bla\n")

        mkfile(@dir, 'version2.txt', "branch: 1.0\nversion: 5\nbuild: 879\nrevision: 79867\ndate: 2008-01-17 16:05:33\n")
        mkfile(@dir, 'version.txt', "")
        mkfile(@dir, 'version-test.txt', "branch: 1.5\nversion: 2\nbuild: 65\nrevision: 64\ndate: 2008-01-02 22:03:10\n")

        mksvndir(mappe)
        mksvndir(@dir)
      end

      def create_design!(force = false, root = 'design')
        return if File.exist?(@dir) && !force

        delete! if File.exist?(@dir)
        mkdir @dir

        mkdesign(root)
      end

      def mkdesign(root, force = false)
        design = mkdir(File.join(@dir, root))

        # JavaScripts
        js = mkdir(File.join(design, 'js'))

        lib_content = <<-EOF
/**
 * Javascript library
 */
var ns = {
  fn: function() {
    alert(''Hey there!);
  }
};

/**
 * A really smart function
 */
function rlySmrt() {
  return 'I am so smart, S-M-R-T';
}
        EOF
        lib = mkfile(js, 'lib.js', lib_content)

        dom_content = <<-EOF
function tis() {
  var just = 'another';
  return just + 'function';
}
        EOF
        dom = mkfile(js, 'dom.js', dom_content)

        yet_content = <<-EOF
/**
 * @depends 'lib.js'
 */
var another = 'file';

function good(stuff, is) {
  var happening = 'now';
}
        EOF
        yet = mkfile(js, 'yet.js', yet_content)

        another_content = <<-EOF
/**
 * This file definately is really nice
 */
var someClass = Base.extend({
  couple: 'of',
  them: false,
  ole: 'properties',

  andThen: function(a, freakin) {
    this.methodMan(a + 3, freakin - 6);
  }

  mehtodMan: function(some, params) {
    return 'ALOHA!';
  }
});
        EOF
        another = mkfile(js, 'another.js', another_content)

        dom_min_content = <<-EOF
/**
 * Simply includes other files to make a monolithic minified file. Du-da, du-da
 * @depends dom.js
 * @depends yet.js
 */
        EOF
        dom_min = mkfile(js, 'dom.min.js', dom_min_content)

        # CSS files
        css = mkdir(File.join(design, 'css'))

        defaults_content = <<-EOF
/**
 * This is a set of defaults for all browsers
 */
* {
  margin: 0;
  padding: 0;
  border: none;
}

h1, h2, h3, h4, h5, h6, p, ol, ul, dl {
  margin: 0 0 1em;
  test-decoration: none;
}
        EOF
        defaults = mkfile(css, 'defaults.css', defaults_content)

        layout_content = <<-EOF
#main_content {
  margin: 0 12px 16px;
  width: 900px;
  border: 3px solid #344;
}

#nav {
  float: left;
  width: 400px;
}
        EOF
        layout = mkfile(css, 'layout.css', layout_content)

        fonts_content = <<-EOF
body {
  font-family: arial, sans-serif;
  font-size: 76%;
}

table {
  font-style: normal;
}
        EOF
        fonts = mkfile(css, 'fonts.css', fonts_content)

        fancy_font_content = <<-EOF
/**
 * Fancy fonts
 */
@import 'fonts.css';

body {
  font-family: tahoma, verdana;
}
        EOF
        fancy_font = mkfile(css, 'fancy_font.css', fancy_font_content)

        layout_min_content = <<-EOF
@import 'defaults.css';
@import 'layout.css';
        EOF
        layout_min = mkfile(css, 'layout.min.css', layout_min_content)

        images = mkdir(File.join(design, 'images'))
        icons = mkdir(File.join(images, 'icons'))
        10.times { |i| mkfile(icons, "icon#{i}.png", "#{i}") }
        15.times { |i| mkfile(images, "img#{i}.gif", "#{i}") }
      end

     private
      # Create a file
      def mkfile(parent, name, content)
        file = File.open(File.join(parent, name), 'w+') { |f| f.puts content }
        @file_count += 1
      end

      def mkdir(dir)
        FileUtils.mkdir(dir)
        @file_count += 1
        dir
      end

      def mksvndir(dir)
        svn_dir = mkdir(File.join(dir, '.svn'))
        mkdir(File.join(svn_dir, 'prop-base'))
        mkdir(File.join(svn_dir, 'props'))
        text_base = mkdir(File.join(svn_dir, 'text-base'))
        tmp = mkdir(File.join(svn_dir, 'tmp'))
        mkdir(File.join(tmp, 'prop-base'))
        mkdir(File.join(tmp, 'props'))
        mkdir(File.join(tmp, 'text-base'))
        mkfile(svn_dir, 'all-wcprops', '')
        mkfile(svn_dir, 'entries', '')
        mkfile(svn_dir, 'format', '')

        Dir.new(dir).each do |f|
          if File.file?(File.join(dir, f)) && !(f =~ /^\.\.?/)
            mkfile(text_base, File.basename(f) + '.svn-base', '')
          end
        end
      end
    end
  end
end

def noout
  std = $stdout
  $stdout = StringIO.new
  res = yield
  $stdout = std
  return res
end
