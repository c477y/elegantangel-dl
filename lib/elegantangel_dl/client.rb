# frozen_string_literal: true

module ElegantAngelDL
  class Client
    attr_reader :cookie_file, :performer_file, :movie_file, :scene_file, :download_dir

    def initialize(cookie_file:, verbose:, performer_file: nil, movie_file: nil, scene_file: nil, download_dir: nil)
      @cookie_file = cookie_file
      @performer_file = performer_file
      @movie_file = movie_file
      @scene_file = scene_file
      @download_dir = download_dir || "."
      ElegantAngelDL.logger(verbose: verbose)
    end

    def start
      ElegantAngelDL.logger.info "[PROCESS START]"
      validate_files!

      process_performer_file
      process_movies_file
      process_scenes_file
      ElegantAngelDL.logger.info "[PROCESS COMPLETED]"
    end

    private

    def validate_files!
      unless [performer_file, movie_file, scene_file].map { |f| !f.nil? && File.file?(f) && File.exist?(f) }.any?
        raise "Must provide one YAML file to begin download."
      end

      raise "invalid cookie file" unless valid_file?(cookie_file)
    end

    def cookie
      @cookie ||= File.read(cookie_file).strip
    end

    def process_performer_file
      return unless valid_file?(performer_file)

      ElegantAngelDL.logger.info "[START] #{performer_file}"
      pages = load_yaml(performer_file)
      download_performer_file(pages)
      ElegantAngelDL.logger.info "[COMPLETE] #{performer_file}"
    end

    def process_movies_file
      return unless valid_file?(movie_file)

      ElegantAngelDL.logger.info "[START] #{movie_file}"
      pages = load_yaml(movie_file)
      download_movie_file(pages)
      ElegantAngelDL.logger.info "[COMPLETE] #{movie_file}"
    end

    def process_scenes_file
      return unless valid_file?(scene_file)

      ElegantAngelDL.logger.info "[START] #{scene_file}"
      pages = load_yaml(scene_file)
      download_movie_file(pages)
      ElegantAngelDL.logger.info "[COMPLETE] #{scene_file}"
    end

    # @param [Array[String] performer_pages
    # @return [NilClass]
    def download_performer_file(performer_pages)
      # binding.pry
      performer_pages.each do |performer_page|
        ElegantAngelDL.logger.info "[PROCESSING] #{performer_page}"
        performer_processor.performer_page = performer_page
        scenes = performer_processor.fetch_scenes
        download_scenes(scenes)
      end
    end

    # @param [Array[String]] movie_pages
    # @return [NilClass]
    def download_movie_file(movie_pages)
      movie_pages.each do |movie_page|
        ElegantAngelDL.logger.info "[PROCESSING] #{movie_page}"
        movie_processor.movie_page = movie_page
        scenes = movie_processor.fetch_scenes
        download_scenes(scenes)
      end
    end

    # @param [Array[String]] scenes
    def download_scenes(scene_pages)
      scene_pages.each do |scene_page|
        ElegantAngelDL.logger.info "[PROCESSING] #{scene_page}"
        m3u8_index = scene_processor.fetch(scene_page)
        ElegantAngelDL.logger.info "[M3U8 MASTER INDEX] #{m3u8_index}"
        download_client.download(m3u8_index) if m3u8_index
      end
    end

    def download_client
      @download_client ||= Download::YoutubeDL.new(download_dir)
    end

    # @return [ElegantAngelDL::Network::Scene]
    def scene_processor
      @scene_processor ||= Network::Scene.new(cookie)
    end

    # @return [ElegantAngelDL::Network::Performer]
    def performer_processor
      @performer_processor ||= Network::Performer.new(cookie)
    end

    # @return [ElegantAngelDL::Network::Movie]
    def movie_processor
      @movie_processor ||= Network::Movie.new(cookie)
    end

    def valid_file?(file)
      !file.nil? && File.file?(file) && File.exist?(file)
    end

    # @param [File] file
    def load_yaml(file)
      YAML.load_file(file)["urls"] || []
    end
  end
end
