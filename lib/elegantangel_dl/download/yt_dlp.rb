# frozen_string_literal: true

module ElegantAngelDL
  module Download
    class YtDLP < Base
      def downloader_path
        @downloader_path ||= begin
          stdout, stderr, status = Open3.capture3("which yt-dlp")
          raise FatalError, stderr unless status.success?

          stdout.strip
        end
      end

      def command(path, uri)
        cmd = [downloader_path, output_file_arg(path), merge_parts_arg, concurrent_download, "\"#{uri}\""].join(" ")
        ElegantAngelDL.logger.debug cmd
        cmd
      end

      private

      def concurrent_download
        "--concurrent-fragments 4"
      end
    end
  end
end
