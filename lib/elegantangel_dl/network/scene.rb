# frozen_string_literal: true

module ElegantAngelDL
  module Network
    class Scene < Base
      attr_reader :scene_url, :scene_title, :movie_title, :m3u8_master_index

      RESOLUTION_REGEX = /.*RESOLUTION=(?<resolution>\d*x\d*).*/x.freeze

      # @param [String] scene_url Link to a scene
      # @return [Data::SceneData] Struct with details of the scene
      def fetch(scene_url, retry_count = 1)
        @scene_url = scene_url
        setup_browser
        return if store.already_downloaded?(scene_url)

        m3u8_link = fetch_m3u8_link
        if m3u8_link.nil?
          ElegantAngelDL.logger.error "[ERR_NO_URL] #{scene_url}"
          return
        end

        @m3u8_master_index = fetch_master_index(m3u8_link)
        Data::SceneData.new(scene_url: @scene_url, scene_title: @scene_title,
                            movie_title: @movie_title, m3u8_master_index: @m3u8_master_index,
                            is_downloaded: false)
      rescue Net::ReadTimeout => e
        raise FatalError, e.message unless retry_count < 3

        ElegantAngelDL.logger.error "[Net::ReadTimeout] #{e.message}"
        new_retry_count = retry_count + 1
        ElegantAngelDL.logger.error "Sleeping for 5 minutes to allow network refresh..."
        sleep(5 * 60 * 60)
        fetch(scene_url, new_retry_count)
      ensure
        close_browser
      end

      private

      # @param [String] m3u8_link
      # @param [String (frozen)] resolution
      def fetch_master_index(m3u8_link, resolution = "1920x1080")
        resp = handle_api_resp(m3u8_link, HTTParty.get(m3u8_link))
        meta_tags = resp.split("\n")

        ElegantAngelDL.logger.debug "M3U8 Index File contents:"
        meta_tags.each { |x| ElegantAngelDL.logger.debug "\t#{x}" }

        # Find the URL with the matching resolution
        meta_tags[1..-2].each_with_index do |meta, index|
          return meta_tags[index + 2] if RESOLUTION_REGEX.match?(meta) && RESOLUTION_REGEX.match(meta)[:resolution] == resolution
        end

        # If the video with the matching resolution does not exist, get the highest available resolution instead
        ElegantAngelDL.logger.debug "Requested resolution not found. Fetching last index file"
        meta_tags.last
      end

      def document_initialised(driver)
        wait.until { driver.find_element(:class, "video-player") }
      end

      def fetch_m3u8_link
        player_url = nil
        m3u8_link = nil
        driver.intercept do |request, &continue|
          uri = URI.parse(request.url)
          player_url = request.url if uri.host == "www.adultempire.com" && uri.path.include?("/gw/player")
          m3u8_link = request.url if uri.path.end_with?("/master.m3u8")
          continue.call(request)
        end
        add_cookie_to_session
        driver.get(scene_url)

        # Fetch the scene and movie title from the page
        video_title = driver.find_element(class: "video-title")
        fetch_scene_title(video_title)
        fetch_movie_title(video_title)

        driver.find_element(xpath: '//*[@id="loadPlayer"]').click
        if player_url.nil?
          ElegantAngelDL.logger.error "Unable to find player link from player action"
          return
        end

        driver.manage.delete_all_cookies
        driver.navigate.to(player_url)
        wait.until { document_initialised(driver) }
        sleep(5) if m3u8_link.nil?
        m3u8_link
      rescue Selenium::WebDriver::Error::NoSuchWindowError
        raise FatalError, "[WEB_DRIVER_EXIT] Browser closed or exited unexpectedly."
      rescue Selenium::WebDriver::Error::TimeoutError => e
        ElegantAngelDL.logger.error "Page failed to load the video player"
        ElegantAngelDL.logger.debug e.message
        nil
      end

      def fetch_scene_title(video_title)
        @scene_title = video_title.find_element(class: "description").text&.strip
      end

      def fetch_movie_title(video_title)
        @movie_title = video_title.find_element(class: "movie-title").text&.strip
      end
    end
  end
end
