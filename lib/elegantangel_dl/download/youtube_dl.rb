# frozen_string_literal: true

module ElegantAngelDL
  module Download
    class YoutubeDL
      attr_reader :uri, :download_dir

      def initialize(download_dir)
        @download_dir = download_dir
        youtube_dl_path
      end

      def download(link)
        @uri = URI.parse(link)
        raise ArgumentError, "#{link} is not a valid m3u8 index link." unless valid_link?

        if file_exists?
          ElegantAngelDL.logger.info "[ERR FILE EXISTS] #{file_name}"
          return
        end
        ElegantAngelDL.logger.info "[DOWNLOAD] #{command}"
        `#{command}`
      end

      private

      def command
        [youtube_dl_path, output_file_arg, merge_parts_arg, "\"#{uri}\""].join(" ")
      end

      def output_file_arg
        path = File.join(download_dir, file_name.to_s)
        "-o '#{path}.%(ext)s'"
      end

      def merge_parts_arg
        "--merge-output-format mkv"
      end

      def file_name
        uri.path.split("/")[-2]
      end

      def file_exists?
        absolute_file_path = File.join(download_dir, "#{file_name}.mp4")
        File.file?(absolute_file_path) && File.exist?(absolute_file_path)
      end

      def valid_link?
        uri.path.end_with?(".m3u8")
      end

      def youtube_dl_path
        @youtube_dl_path ||= begin
          system("youtube-dl --version", exception: true)
          `which youtube-dl`.chomp
        end
      end
    end
  end
end
