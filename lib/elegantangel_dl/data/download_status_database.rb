# frozen_string_literal: true

require "yaml/store"

module ElegantAngelDL
  module Data
    class DownloadStatusDatabase
      attr_reader :store, :semaphore, :scene_data_urls

      def initialize(store_file, semaphore)
        path = File.join(Dir.pwd, store_file)
        ElegantAngelDL.logger.info "[DATABASE_INIT] #{path}"

        @store = YAML::Store.new path
        @semaphore = semaphore
        @scene_data_urls = Set.new
      end

      def file_downloaded?(key)
        semaphore.synchronize do
          store.transaction(true) do
            scene_data = store.fetch(key, nil)
            return false unless scene_data

            if scene_data.is_downloaded == true
              ElegantAngelDL.logger.info "[ERR_FILE_DOWNLOADED] #{scene_data.file_name}"
              return true
            end
          end
        end
      end

      def save_download(scene_data, is_downloaded: false)
        semaphore.synchronize do
          ElegantAngelDL.logger.info "[ADD_TO_DATABASE] #{scene_data.file_name}"
          store.transaction do
            scene_data[:is_downloaded] = is_downloaded
            store[scene_data.key] = scene_data
          end
        end
      end

      def already_downloaded?(scene_url)
        return if scene_data_urls.member?(scene_url)

        store.transaction(true) do
          store.roots.each do |key|
            scene_data = store.fetch(key)
            next unless scene_data.is_downloaded == true

            scene_data_urls.add(scene_data.scene_url)
            if scene_data.scene_url == scene_url
              ElegantAngelDL.logger.info "[ERR_FILE_DOWNLOADED] #{scene_data.file_name}"
              return true
            end
          end
        end
        false
      end
    end
  end
end
