module Juicer
  class DependencyResolver
    include Enumerable
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
    def resolve(file, &block)
      @files = []
      _resolve(file, &block)
    end

    #
    # Yield files recursively. Resolve dependencies first, then call each, or
    # any other enumerable methods.
    #
    def each(&block)
      @files.each(&block)
    end

    #
    # Resolves a path relative to another. If the path is absolute (ie it
    # starts with a protocol or /) the <tt>:document_root</tt> options has to be
    # set as well.
    #
    def resolve_path(path, reference)
      # Absolute URL
      if path =~ %r{^(/|[a-z]+:)}
        if @options[:document_root].nil?
          msg = "Cannot resolve absolute path '#{path}' without document root option"
          raise ArgumentError.new(msg)
        end

        path.sub!(%r{^[a-z]+://[^/]+/}, '')
        return File.expand_path(File.join(@options[:document_root], path))
      end

      File.expand_path(File.join(File.dirname(reference), path))
    end

    private
    def parse(line)
      raise NotImplementedError.new
    end

    def extension
      raise NotImplementedError.new
    end

    #
    # Carries out the actual work of resolve. resolve resets the internal
    # file list and yields control to _resolve for rebuilding the file list.
    #
    def _resolve(file)
      imported_path = nil

      IO.foreach(file) do |line|
        # Implementing subclasses may throw :done from the parse method when
        # the file is exhausted for dependency declaration possibilities.
        catch(:done) do
          imported_path = parse(line, imported_path)

          # If a dependency declaration was found
          if imported_path
            # Resolves a path relative to the file that imported it
            imported_path = resolve_path(imported_path, file)

            if File.directory?(imported_path)
              imported_files = Dir.glob(File.join(imported_path, "**", "*#{extension}"))
            else
              imported_files = [imported_path]
            end

            imported_files.each do |imported_file|
              # Only keep processing file if it's not already included.
              # Yield to block to allow caller to ignore file
              if !@files.include?(imported_file) && (!block_given? || yield(imported_file))
                # Check this file for imports before adding it to get order right
                _resolve(imported_file) { |f| f != File.expand_path(file) }
              end
            end
          end
        end
      end

      file = File.expand_path(file)
      @files << file if !@files.include?(file) && (!block_given? || yield(file))
    end
  end
end
