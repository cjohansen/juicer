# Merge several files into one single output file
module Juicer
  module Merger
    class Base
      attr_reader :files

      def initialize(files = [], options = {})
        @files = []
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
      # written. If a stream is provided, contents are written to it. Without
      # parameters the contents are returned as a string
      #
      def save(file_or_stream = nil)
        unless file_or_stream
          str = ''
          @files.each { |file| str += merge(file) }
          return str
        end

        output = file_or_stream.is_a? String ? File.open(filename, 'w') : file_or_stream
        @files.each { |f| output.puts(merge(f)) }
        output.close if file_or_stream.is_a? String

        return true
      end

     private
      def resolve_dependencies(file)
        @dependency_resolver.resolve(file) do |f|
          if @files.include?(f)
            false
          else
            @files << f
            resolve_dependencies(f)
            true
          end
        end
      end

      # Fetch contents of a single file. May be overridden in subclasses to provide
      # custom content filtering
      def merge(file)
        IO.read(file) + "\n"
      end

      def dependency_resolver=(resolver)
        @dependency_resolver = resolver
      end

      def dependency_resolver()
        @dependency_resolver
      end
    end
  end
end
