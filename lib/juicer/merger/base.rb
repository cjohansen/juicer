require "juicer/chainable"

# Merge several files into one single output file
module Juicer
  module Merger
    class Base
      include Chainable
      attr_accessor :dependency_resolver
      attr_reader :files

      def initialize(files = [], options = {})
        @files = []
        @root = nil
        @options = options
        @dependency_resolver ||= nil
        self.append files
      end

      #
      # Append contents to output. Resolves dependencies and adds
      # required files recursively
      # file = A file to add to merged content
      #
      def append(file)
        return file.each { |f| self << f } if file.class == Array
        return if @files.include?(file)

        if !@dependency_resolver.nil?
          path = File.expand_path(file)
          resolve_dependencies(path)
        elsif !@files.include?(file)
          @files << file
        end
      end

      alias_method :<<, :append

      #
      # Save the merged contents. If a filename is given the new file is
      # written. If a stream is provided, contents are written to it.
      #
      def save(file_or_stream)
        output = file_or_stream

        if output.is_a? String
          @root = Pathname.new(File.dirname(File.expand_path(output)))
          output = File.open(output, 'w')
        else
          @root = Pathname.new(File.expand_path("."))
        end

        @files.each do |f|
          output.puts(merge(f))
        end

        output.close if file_or_stream.is_a? String
      end

      chain_method :save

     private
      def resolve_dependencies(file)
        @files.concat @dependency_resolver.resolve(file)
        @files.uniq!
      end

      # Fetch contents of a single file. May be overridden in subclasses to provide
      # custom content filtering
      def merge(file)
        IO.read(file) + "\n"
      end
    end
  end
end
