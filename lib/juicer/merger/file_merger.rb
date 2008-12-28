# Merge several files into one single output file
module Juicer
  module Merger
    class FileMerger
      attr_reader :files

      # Constructor
      def initialize(files = [], options = {})
        @files = []
        @dependency_resolver ||= nil
        self.<< files
      end

      # Append file contents to output. Resolves dependencies and adds
      # required files recursively
      # file = A file to add to the merged file
      def <<(file)
        return file.each { |f| self << f } if file.class == Array
        return if @files.include?(file)

        if !@dependency_resolver.nil?
          #path = file =~ /^\/|([a-zA-Z]\:)/ ? file : File.join(FileUtils.pwd, file)
          path = File.expand_path(file)
          resolve_imports(path)
        elsif !@files.include?(file)
          @files << file
        end
      end

      # Save the merged file. If a filename is given the new file is written,
      # otherwise the contents are returned as a string
      def save(filename = nil)
        if filename.nil?
          str = ''
          @files.each { |file| str += merge(file) }
          return str
        end

        file = File.new(filename, 'w')
        @files.each { |f| file.puts(merge(f)) }
        file.close
        return true
      end

     private
      def resolve_imports(file)
        @dependency_resolver.resolve(file) do |f|
          if @files.include?(f)
            false
          else
            @files << f
            resolve_imports(f)
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
