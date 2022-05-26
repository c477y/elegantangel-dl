# frozen_string_literal: true

module ElegantAngelDL
  module Data
    SceneData = Struct.new(:scene_url, :scene_title, :movie_title, :m3u8_master_index, :is_downloaded, keyword_init: true) do
      def key
        scene_title.gsub(/[\s\W_]/, "").downcase
      end

      def file_name
        "#{movie_title} [T] #{scene_title}".gsub(/[^\s\w\[\].]+/i, "")
      end

      def uri
        URI.parse(m3u8_master_index)
      end
    end
  end
end
