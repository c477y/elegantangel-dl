# frozen_string_literal: true

module ElegantAngelDL
  module Download
    class YoutubeDL
      def youtube_dl_path
        @youtube_dl_path ||= begin
          system("youtube-dl --version", exception: true)
          `which youtube-dl`.chomp
        end
      end
    end
  end
end
