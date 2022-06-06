# frozen_string_literal: true

module ElegantAngelDL
  module Download
    class YoutubeDL < Base
      def downloader_path
        @downloader_path ||= super("youtube-dl")
      end

      def command(path, uri)
        cmd = [downloader_path, output_file_arg(path), merge_parts_arg, "\"#{uri}\""].join(" ")
        ElegantAngelDL.logger.debug cmd
        cmd
      end
    end
  end
end
