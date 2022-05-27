# frozen_string_literal: true

module ElegantAngelDL
  class Client
    attr_reader :cookie_file, :performer_file, :movie_file, :scene_file, :download_dir, :parallel, :store, :downloader

    def initialize(cookie_file:, verbose:, performer_file: nil, movie_file: nil, scene_file: nil,
                   download_dir: nil, parallel: nil, store: nil, downloader: nil)
      ElegantAngelDL.logger(verbose: verbose)
      @cookie_file = set(cookie_file, "cookie.txt")
      @performer_file = set(performer_file, "performers.yml")
      @movie_file = set(movie_file, "movies.yml")
      @scene_file = set(scene_file, "scenes.yml")
      @download_dir = set(download_dir, ".")
      @parallel = set(parallel&.to_i, 4)
      @store = set(store, "download_status.store")
      @downloader = set(downloader, "youtube-dl")
      init_vars
    end

    def init_vars
      download_client
      download_status_store
    end

    def start
      ElegantAngelDL.logger.info "[PROCESS START]"
      validate_files!

      process_performer_file
      process_movies_file
      process_scenes_file
      ElegantAngelDL.logger.info "[PROCESS COMPLETED]"
    rescue FatalError => e
      ElegantAngelDL.logger.error e.message
    end

    private

    def validate_files!
      raise "Must provide atleast one YAML file to begin download." unless [performer_file, movie_file, scene_file].map { |f| valid_file?(f) }.any?

      raise "invalid cookie file" unless valid_file?(cookie_file)
    end

    def set(value, default = nil)
      value || default
    end

    def cookie
      @cookie ||= File.read(cookie_file).strip
    end

    def process_performer_file
      return unless valid_file?(performer_file)

      ElegantAngelDL.logger.info "[START_PERFORMER] #{performer_file}"
      pages = load_yaml(performer_file)
      download_performer_file(pages)
      ElegantAngelDL.logger.info "[COMPLETE_PERFORMER] #{performer_file}"
    end

    def process_movies_file
      return unless valid_file?(movie_file)

      ElegantAngelDL.logger.info "[START_MOVIE] #{movie_file}"
      pages = load_yaml(movie_file)
      download_movie_file(pages)
      ElegantAngelDL.logger.info "[COMPLETE_MOVIE] #{movie_file}"
    end

    def process_scenes_file
      return unless valid_file?(scene_file)

      ElegantAngelDL.logger.info "[START_SCENE] #{scene_file}"
      pages = load_yaml(scene_file)
      download_scenes(pages)
      ElegantAngelDL.logger.info "[COMPLETE_SCENE] #{scene_file}"
    end

    # @param [Array[String] performer_pages
    # @return [NilClass]
    def download_performer_file(performer_pages)
      performer_pages.each do |performer_page|
        ElegantAngelDL.logger.info "[PROCESSING_PERFORMER] #{performer_page}"
        performer_processor.performer_page = performer_page
        scenes = performer_processor.fetch_scenes
        download_scenes(scenes)
      end
    end

    # @param [Array[String]] movie_pages
    # @return [NilClass]
    def download_movie_file(movie_pages)
      movie_pages.each do |movie_page|
        ElegantAngelDL.logger.info "[PROCESSING_MOVIE] #{movie_page}"
        movie_processor.movie_page = movie_page
        scenes = movie_processor.fetch_scenes
        download_scenes(scenes)
      end
    end

    # @param [Array[String]] scenes
    def download_scenes(scene_pages)
      scene_pages.each_slice(parallel) do |batch|
        urls = batch.map { |x| scene_processor.fetch(x) }.compact
        Parallel.map(urls, in_threads: parallel) do |url|
          Download::Downloader.new(download_client, download_status_store, download_dir).download(url)
        end
      end
    end

    def download_client
      @download_client ||= case downloader
                           when "youtube-dl" then @download_client ||= Download::YoutubeDL.new
                           when "yt-dlp" then @download_client ||= Download::YtDLP.new
                           else raise FatalError, "Invalid downloader. Use 'youtube_dl'(default) or 'yt-dlp'"
                           end
    end

    # @return [ElegantAngelDL::Network::Scene]
    def scene_processor
      @scene_processor ||= Network::Scene.new(cookie, download_status_store)
    end

    # @return [ElegantAngelDL::Network::Performer]
    def performer_processor
      @performer_processor ||= Network::Performer.new(cookie, download_status_store)
    end

    # @return [ElegantAngelDL::Network::Movie]
    def movie_processor
      @movie_processor ||= Network::Movie.new(cookie, download_status_store)
    end

    def download_status_store
      @download_status_store ||= Data::DownloadStatusDatabase.new(@store, semaphore)
    end

    def valid_file?(file)
      !file.nil? && File.file?(file) && File.exist?(file)
    end

    # @param [File] file
    def load_yaml(file)
      YAML.load_file(file)["urls"] || []
    end

    def semaphore
      @semaphore ||= Mutex.new
    end
  end
end
