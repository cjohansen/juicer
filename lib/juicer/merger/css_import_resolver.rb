module Juicer
  module Merger
    # Resolves @import statements in CSS files
    class CssImportResolver
      attr_reader :files

      # Constructor
      def initialize(options = {})
        @files = []
      end

      def resolve(file)
        imported_file = nil
        @files = []

        IO.foreach(file) do |line|
          if line =~ /^\s*\@import\s("|')(.*)("|')\;?/
            imported_file = File.expand_path(File.join(File.dirname(file), $2))

            if yield imported_file
              @files << imported_file
            end
          else
            # If we have already skimmed through some @imports and
            # this line contains anything other than spaces or a comment,
            # we're done.
            break if imported_file && line =~ %r{/*}
            break if line =~ /^[\.\#a-zA-Z\:]/
          end
        end

        @files << File.expand_path(file) if yield File.expand_path(file)
        return @files
      end
    end
  end
end
