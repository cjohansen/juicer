require "juicer/binary"

module Juicer
  #
  # A Ruby API to Douglas Crockfords genious JsLint program
  # http://www.jslint.com/
  #
  # JsLint parses JavaScript code and identifies (potential) problems.
  # Effectively, JsLint defines a subset of JavaScript which is safe to use, and
  # among other things make code minification a substantially less dangerous
  # task.
  #
  class JsLint
    include Juicer::Binary

    def initialize(options = {})
      super(options[:java] || "java")
      path << options[:bin_path] if options[:bin_path]
    end

    #
    # Checks if a files has problems. Also includes experimental support for CSS
    # files. CSS files should begin with the line @charset "UTF-8";
    #
    # Returns a Juicer::JsLint::Report object
    #
    def check(file)
      rhino_jar = rhino
      js_file = locate_lib

      raise FileNotFoundError.new("Unable to locate Rhino jar '#{rhino_jar}'") if !rhino_jar || !File.exists?(rhino_jar)
      raise FileNotFoundError.new("Unable to locate JsLint '#{js_file}'") if !js_file || !File.exists?(js_file)
      raise FileNotFoundError.new("Unable to locate input file '#{file}'") unless File.exists?(file)

      lines = execute(%Q{-jar "#{rhino}" "#{locate_lib}" "#{file}"}).split("\n")
      return Report.new if lines.length == 1 && lines[0] =~ /jslint: No problems/

      report = Report.new
      lines = lines.reject { |line| !line || "#{line}".strip == "" }
      report.add_error(lines.shift, lines.shift) while lines.length > 0

      return report
    end

    def rhino
      files = locate("**/rhino*.jar", "RHINO_HOME")
      !files || files.empty? ? nil : files.sort.last
    end

    def locate_lib
      files = locate("**/jslint-*.js", "JSLINT_HOME")
      !files || files.empty? ? nil : files.sort.last
    end

    #
    # Represents the results of a JsLint run
    #
    class Report
      attr_accessor :errors

      def initialize(errors = [])
        @errors = errors
      end

      def add_error(message, code)
        @errors << JsLint::Error.new(message, code)
      end

      def ok?
        @errors.nil? || @errors.length == 0
      end
    end

    #
    # A JsLint error
    #
    class Error
      attr_accessor :message, :code

      def initialize(message, code)
        @message = message
        @code = code
      end

      def to_s
        "#@message\n#@code"
      end
    end
  end
end
