require "juicer/dependency_resolver/dependency_resolver"

module Juicer
  # Resolves @depends and @depend statements in comments in JavaScript files.
  # Only the first comment in a JavaScript file is parsed
  #
  class JavaScriptDependencyResolver < DependencyResolver
    @@depends_pattern = /\@depends?\s+([^\s\'\"\;]+)/

    private
    def parse(line, imported_file = nil)
      return $1 if line =~ @@depends_pattern

      # If we have already skimmed through some @depend/@depends or a
      # closing comment we're done.
      throw :done unless imported_file.nil? || !(line =~ /\*\//)
    end

    def extension
      ".js"
    end
  end
end
