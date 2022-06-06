# frozen_string_literal: true

module ElegantAngelDL
  module Download
    class YtDLP < Base
      def downloader_path
        @downloader_path ||= super("yt-dlp")
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
