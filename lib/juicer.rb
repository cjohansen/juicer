require "logger"

module Juicer

  # :stopdoc:
  VERSION = '1.0.11'
  LIBPATH = ::File.expand_path(::File.dirname(__FILE__)) + ::File::SEPARATOR
  PATH = ::File.dirname(LIBPATH) + ::File::SEPARATOR
  LOGGER = Logger.new(STDOUT)
  @@home = nil
  # :startdoc:

  # Returns the version string for the library.
  #
  def self.version
    VERSION
  end

  # Returns the installation directory for Juicer
  #
  def self.home
    return @@home if @@home
    return ENV['JUICER_HOME'] if ENV['JUICER_HOME']
    return File.join(ENV['HOME'], ".juicer") if ENV['HOME']
    return File.join(ENV['APPDATA'], "juicer") if ENV['APPDATA']
    return File.join(ENV['HOMEDRIVE'], ENV['HOMEPATH'], "juicer") if ENV['HOMEDRIVE'] && ENV['HOMEPATH']
    return File.join(ENV['USERPROFILE'], "juicer") if ENV['USERPROFILE']
    return File.join(ENV['Personal'], "juicer") if ENV['Personal']
  end

  # Set home directory
  #
  def self.home=(home)
    @@home = home
  end

  # Returns the library path for the module. If any arguments are given,
  # they will be joined to the end of the libray path using
  # <tt>File.join</tt>.
  #
  def self.libpath( *args )
    args.empty? ? LIBPATH : ::File.join(LIBPATH, args.flatten)
  end

  # Returns the lpath for the module. If any arguments are given,
  # they will be joined to the end of the path using
  # <tt>File.join</tt>.
  #
  def self.path( *args )
    args.empty? ? PATH : ::File.join(PATH, args.flatten)
  end

  # Utility method used to require all files ending in .rb that lie in the
  # directory below this file.
  def self.require_all_libs
    dir  = File.dirname(File.expand_path(__FILE__))
    glob = File.join(dir, "juicer", '**', '*.rb')

    # Unexpand paths (avoids requiring the same file twice)
    paths = Dir.glob(glob).map { |path| path.sub("#{dir}/", '').sub(/\.rb$/, "") }
    paths.each { |rb| require rb }
  end

end

Juicer.require_all_libs

class FileNotFoundError < Exception
end
