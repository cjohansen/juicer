require "pathname"

module Juicer
  module Command
    # Utilities for Juicer command objects
    #
    module Util
      # Returns an array of files from a variety of input. Input may be a single
      # file, a single glob pattern or multiple files and/or patterns. It may
      # even be an array of mixed input.
      #
      def files(*args)
        args.flatten.collect { |file| Dir.glob(file) }.flatten
      end

      #
      # Uses Pathname to calculate the shortest relative path from +path+ to
      # +reference_path+ (default is +Dir.cwd+)
      #
      def relative(paths, reference_path = Dir.pwd)
        paths = [paths].flatten.collect do |path|
          path = Pathname.new(File.expand_path(path))
          reference_path = Pathname.new(File.expand_path(reference_path))
          path.relative_path_from(reference_path).to_s
        end

        paths.length == 1 ? paths.first : paths
      end
    end
  end
end

