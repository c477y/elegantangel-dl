# frozen_string_literal: true

module ElegantAngelDL
  module Download
    class Downloader
      extend Forwardable

      SEGMENT_DOWNLOAD_LOG = /.*\/seg-(?<segment>\d+)-[\w-]+\.ts.*/x.freeze

      attr_reader :download_dir, :client, :store

      def_delegators :@scene_data, :scene_url, :scene_title, :movie_title, :m3u8_master_index, :uri, :file_name

      # @param [Download::YoutubeDL] client
      # @param [Data::DownloadStatusDatabase] store
      # @param [String] download_dir
      def initialize(client, store, download_dir)
        @client = client
        @store = store
        @download_dir = download_dir
      end

      # @param [Data::SceneData] scene_data
      def download(scene_data)
        @scene_data = scene_data
        raise ArgumentError, "#{m3u8_master_index} is not a valid m3u8 index link." unless valid_link?

        if file_exists?
          ElegantAngelDL.logger.info "[ERR_FILE_EXISTS] #{file_name}"
          store.save_download(scene_data, is_downloaded: true) unless store.file_downloaded?(scene_data.key)
        elsif store.file_downloaded?(scene_data.key)
          nil
        else
          start_shell
        end
      end

      private

      def start_shell
        Open3.popen2e(command) do |_, stdout_and_stderr, wait_thr|
          output = []
          pid = wait_thr.pid
          ElegantAngelDL.logger.info "[PID] #{pid}. FILE #{file_name}"
          stdout_and_stderr.each do |line|
            output << line
            ElegantAngelDL.youtube_dl_logger.info("#{pid} -- #{line}")
            next unless SEGMENT_DOWNLOAD_LOG.match?(line)
          end
          exit_status = wait_thr.value
          if exit_status != 0
            store.save_download(@scene_data, is_downloaded: false)
            ElegantAngelDL.logger.error "[DOWNLOAD_FAIL] #{file_name} -- #{output[-2].strip}"
            ElegantAngelDL.logger.error "[DOWNLOAD_FAIL] #{file_name} -- #{output[-1].strip}"
          else
            store.save_download(@scene_data, is_downloaded: true)
            ElegantAngelDL.logger.info "[DOWNLOAD_COMPLETE] #{file_name}"
          end
        end
      end

      def print_line(line)
        return if line == '\n'

        ElegantAngelDL.logger.error line.strip
      end

      def command
        [client, output_file_arg, merge_parts_arg, "\"#{uri}\""].join(" ")
      end

      def output_file_arg
        path = File.join(download_dir, file_name.to_s)
        "-o '#{path}.%(ext)s'"
      end

      def merge_parts_arg
        "--merge-output-format mkv"
      end

      def file_exists?
        absolute_file_path = File.join(download_dir, "#{file_name}.mp4")
        File.file?(absolute_file_path) && File.exist?(absolute_file_path)
      end

      def valid_link?
        uri.path.end_with?(".m3u8")
      end
    end
  end
end
