module Juicer
  module Merger
    class DependencyResolver
      attr_reader :files

      # Constructor
      def initialize(options = {})
        @files = []
        @options = options
      end

      #
      # Resolve dependencies.
      # This method accepts an optional block. The block will receive each
      # file in succession. The file is included in the returned collection
      # if the block is true for the given file. Without a block every found
      # file is returned.
      #
      def resolve(file)
        imported_file = nil
        @files = []

        catch(:done) do
          IO.foreach(file) do |line|
            imported_file = parse(line, imported_file)

            if imported_file
              imported_file = resolve_path(imported_file, file)
              @files << imported_file if !block_given? || yield(imported_file)
            end
          end
        end

        file = File.expand_path(file)
        @files << file if !block_given? || yield(file)
      end

      #
      # Resolves a path relative to another. If the path is absolute (ie it
      # starts with a protocol or /) the <tt>:web_root</tt> options has to be
      # set as well.
      #
      def resolve_path(path, reference)
        # Absolute URL
        if path =~ %r{^(/|[a-z]+:)}
          if @options[:web_root].nil?
            msg = "Cannot resolve absolute path '#{path}' without web root option"
            raise ArgumentError.new(msg)
          end

          path.sub!(%r{^[a-z]+://[^/]+/}, '')
          return File.expand_path(File.join(@options[:web_root], path))
        end

        File.expand_path(File.join(File.dirname(reference), path))
      end

     private
      def parse(line)
        raise NotImplementedError.new
      end
    end
  end
end
