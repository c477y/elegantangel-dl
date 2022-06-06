# frozen_string_literal: true

module ElegantAngelDL
  module Download
    class Base
      def downloader_path(downloader)
        stdout, stderr, status = Open3.capture3("which #{downloader}")
        raise FatalError, stderr unless status.success?

        stdout.strip
      end

      def command(_path, _uri)
        raise "Not Implemented"
      end

      def output_file_arg(path)
        "-o '#{path}.%(ext)s'"
      end

      def merge_parts_arg
        "--merge-output-format mkv"
      end
    end
  end
end
