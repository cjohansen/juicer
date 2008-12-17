= Juicer
    by Christian Johansen
    http://www.cjohansen.no/en/projects/juicer

== DESCRIPTION:

Juicer is a command line tool aimed at easing JavaScript and CSS development.
Currently it only provides a wrapper to YUI Compressor along with a module that
can dynamically link together files, but there are plans for more functionality.

== FEATURES/PROBLEMS:

Juicer can read @import statements in CSS files and use them to combine all your
stylesheets into a single file. This file may be minified using the YUI
Compressor. Eventually it will support other minifying tools too.

Juicer can treat your JavaScript files much the same way too, parsing a comment
switch @depends

== SYNOPSIS:

  juicer myfile.css
  -> Produces myfile.min.css which may contain several CSS files, minified

  juicer myfile.js
  -> Produces myfile.min.js, minified and combined

== REQUIREMENTS:

In order to use YUI Compressor you need Java installed and the java executable
available on your path.

== INSTALL:

  $ gem sources -a http://gems.github.com
  $ gem install cjohansen-juicer

== LICENSE:

Please note that the YUI Compressor which is distributed along with
Juicer is licensed under the BSD license.

(The MIT License)

Copyright (c) 2008 Christian Johansen

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
