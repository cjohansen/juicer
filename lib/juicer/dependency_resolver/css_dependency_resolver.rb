require "juicer/dependency_resolver/dependency_resolver"

module Juicer

  # Resolves @import statements in CSS files and builds a list of all
  # files, in order.
  #
  class CssDependencyResolver < DependencyResolver
    # Regexp borrowed from similar project:
    # http://github.com/cgriego/front-end-blender/tree/master/lib/front_end_architect/blender.rb
    @@import_pattern = /^\s*@import(?:\surl\(|\s)(['"]?)([^\?'"\)\s]+)(\?(?:[^'"\)]*))?\1\)?(?:[^?;]*);?/im

    private
    def parse(line, imported_file = nil)
      return $2 if line =~ @@import_pattern

      # At first sight of actual CSS rules we abort (TODO: This does not take
      # into account the fact that rules may be commented out and that more
      # imports may follow)
      throw :done if imported_file && line =~ %r{/*}
      throw :done if line =~ /^[\.\#a-zA-Z\:]/
    end

    def extension
      ".css"
    end
  end

end
