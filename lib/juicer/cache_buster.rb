# -*- coding: utf-8 -*-

module Juicer
  #
  # Assists in creating filenames that reflect the last change to the file. These
  # kinds of filenames are useful when serving static content through a web server.
  # If the filename changes everytime the file is modified, you can safely configure
  # the web server to cache files indefinately, and know that the updated filename
  # will cause the file to be downloaded again - only once - when it has changed.
  #
  # = Types of cache busters
  #
  # == Query string / "soft" cache busters
  # Soft cache busters require no web server configuration. However, it is not
  # guaranteed to work in all settings. For example, older default
  # configurations for popular proxy server Squid does not consider a known URL
  # with a new query string a new URL, and thus will not download the file over.
  #
  # The soft cache busters transforms
  # <tt>/images/logo.png</tt> to <tt>/images/logo.png?cb=1232923789</tt>
  #
  # == Filename change / "hard" cache busters
  # Hard cache busters change the file name itself, and thus requires either
  # the web server to (internally) rewrite requests for these files to the
  # original ones, or the file names to actually change. Hard cache busters
  # transforms <tt>/images/logo.png</tt> to <tt>/images/logo-1232923789.png</tt>
  #
  # Hard cache busters are guaranteed to work, and is the recommended variant.
  # An example configuration for the Apache web server that does not require
  # you to actually change the filenames can be seen below.
  #
  #   <VirtualHost *>
  #       # Application/website configuration
  #
  #       # Cache static resources for a year
  #       <FilesMatch "\.(ico|pdf|flv|jpg|jpeg|png|gif|js|css|swf)$">
  #           ExpiresActive On
  #           ExpiresDefault "access plus 1 year"
  #       </FilesMatch>
  #
  #       # Rewrite URLs like /images/logo-cb1234567890.png to /images/logo.png
  #       RewriteEngine On
  #       RewriteRule (.*)-cb\d+\.(.*)$ $1.$2 [L]
  #   </VirtualHost>])
  #
  # = Consecutive calls
  #
  # Consecutive calls to add a cache buster to a path will replace the existing
  # cache buster *as long as the parameter name is the same*. Consider this:
  #
  #   file = Juicer::CacheBuster.hard("/home/file.png") #=> "/home/file-cb1234567890.png"
  #   Juicer::CacheBuster.hard(file)                    #=> "/home/file-cb1234567891.png"
  #
  #   # Changing the parameter name breaks this
  #   Juicer::CacheBuster.hard(file, :juicer)           #=> "/home/file-cb1234567891-juicer1234567892.png"
  #
  # Avoid this type of trouble simply be cleaning the URL with the old name first:
  #
  #   Juicer::CacheBuster.clean(file)                   #=> "/home/file.png"
  #   file = Juicer::CacheBuster.hard(file, :juicer)    #=> "/home/file-juicer1234567892.png"
  #   Juicer::CacheBuster.clean(file, :juicer)          #=> "/home/file.png"
  #
  # Author::    Christian Johansen (christian@cjohansen.no)
  # Copyright:: Copyright (c) 2009 Christian Johansen
  # License::   BSD
  #
  module CacheBuster
    DEFAULT_PARAMETER = "jcb"

    #
    # Creates a unique file name for every revision to the files contents.
    # Raises an <tt>ArgumentError</tt> if the file can not be found.
    #
    # The type indicates which type of cache buster you want, <tt>:soft</tt>
    # or <tt>:hard</tt>. Default is <tt>:soft</tt>. If an unsupported value
    # is specified, <tt>:soft</tt> will be used.
    #
    # See <tt>#hard</tt> and <tt>#soft</tt> for explanation of the parameter
    # argument.
    #
    def self.path(file, type = :soft, parameter = DEFAULT_PARAMETER)
      return file if file =~ /data:.*;base64/
      type = [:soft, :hard, :rails].include?(type) ? type : :soft
      parameter = nil if type == :rails
      file = self.clean(file, parameter)
      filename = file.split("?").first
      raise ArgumentError.new("#{file} could not be found") unless File.exists?(filename)
      mtime = File.mtime(filename).to_i

      if type == :soft
        parameter = "#{parameter}=".sub(/^=$/, '')
        return "#{file}#{file.index('?') ? '&' : '?'}#{parameter}#{mtime}"
      elsif type == :rails
        return "#{file}#{file.index('?') ? '' : "?#{mtime}"}"
      end

      file.sub(/(\.[^\.]+$)/, "-#{parameter}#{mtime}" + '\1')
    end

    #
    # Add a hard cache buster to a filename. The parameter is an optional prefix
    # that is added before the mtime timestamp. It results in filenames of the form:
    # <tt>file-[parameter name][timestamp].suffix</tt>, ie
    # <tt>images/logo-cb1234567890.png</tt> which is the case for the default
    # parameter name "cb" (as in *c*ache *b*uster).
    #
    def self.hard(file, parameter = DEFAULT_PARAMETER)
      self.path(file, :hard, parameter)
    end

    #
    # Add a soft cache buster to a filename. The parameter is an optional name
    # for the mtime timestamp value. It results in filenames of the form:
    # <tt>file.suffix?[parameter name]=[timestamp]</tt>, ie
    # <tt>images/logo.png?cb=1234567890</tt> which is the case for the default
    # parameter name "cb" (as in *c*ache *b*uster).
    #
    def self.soft(file, parameter = DEFAULT_PARAMETER)
      self.path(file, :soft, parameter)
    end

    #
    # Add a Rails-style cache buster to a filename. Results in filenames of the
    # form: <tt>file.suffix?[timestamp]</tt>, ie <tt>images/logo.png?1234567890</tt>
    # which is the format used by Rails' image_tag helper.
    #
    def self.rails(file)
      self.path(file, :rails)
    end
    
    #
    # Remove cache buster from a URL for a given parameter name. Parameter name is
    # "cb" by default.
    #
    def self.clean(file, parameter = DEFAULT_PARAMETER)
      if "#{parameter}".length == 0
        return file.sub(/\?\d+$/, '')
      else
        query_param = "#{parameter}="
        new_file = file.sub(/#{query_param}\d+&?/, "").sub(/(\?|&)$/, "")
        return new_file unless new_file == file

        file.sub(/-#{parameter}\d+(\.\w+)($|\?)/, '\1\2')
      end
    end
  end
end
