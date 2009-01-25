module Juicer
  #
  # Tool that assists in creating filenames that update everytime the file
  # contents change. There's two ways of generating filenames, soft and hard.
  # The point of all this is to facilitate configuring web servers to send
  # static assets with a far future expires header - improving end user
  # performance through caching.
  #
  # Soft cache busters require no web server configuration, but will not work
  # as intended with older default configurations for popular proxy server
  # Squid. The soft busters use query parameters to create unique file names,
  # and these may not force an update in some cases. The soft cache busters
  # transforms /images/logo.png to /images/logo.png?cb=1232923789
  #
  # Hard cache busters change the file name itself, and thus requires either
  # the web server to (internally) rewrite requests for these files to the
  # original ones, or the file names to actually change. Hard cache busters
  # transforms /images/logo.png to /images/logo-1232923789.png
  #
  module CacheBuster
    #
    # Creates a unique file name for every revision to the files contents.
    # Default parameter name for soft cache busters is cb (ie ?cb=<timestamp>)
    # while default parameter names for hard cache busters is none (ie
    # file-<timestamp>.png).
    #
    def self.path(file, type = :soft, param = :undef)
      param = (type == :soft ? "jcb" : nil) if param == :undef
      mtime = File.new(file).mtime.to_i

      if type == :soft
        param = "#{param}".length == 0 ? "" : "#{param}="
        "#{file}#{file.index('?') ? '&' : '?'}#{param}#{mtime}"
      else
        parts = file.split(".")
        suffix = parts.pop
        "#{parts.join('.')}-#{param}#{mtime}.#{suffix}"
      end
    end
  end
end
