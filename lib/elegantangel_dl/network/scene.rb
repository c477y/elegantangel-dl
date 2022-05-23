# frozen_string_literal: true

module ElegantAngelDL
  module Network
    class Scene < Base
      attr_reader :scene_url

      RESOLUTION_REGEX = /.*RESOLUTION=(?<resolution>\d*x\d*).*/x.freeze

      # @param [String] scene_url Link to a scene
      # @return [String] Master M3U8 index file
      def fetch(scene_url)
        setup_browser
        @scene_url = scene_url
        m3u8_link = fetch_m3u8_link
        return if m3u8_link.nil?

        fetch_master_index(m3u8_link)
      ensure
        close_browser
      end

      private

      # @param [String] m3u8_link
      # @param [String (frozen)] resolution
      def fetch_master_index(m3u8_link, resolution = "1280x720")
        resp = handle_api_resp(m3u8_link, HTTParty.get(m3u8_link))
        meta_tags = resp.split("\n")

        ElegantAngelDL.logger.debug "M3U8 Index File contents:"
        meta_tags.each { |x| ElegantAngelDL.logger.debug x }

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
          m3u8_link = request.url if uri.host == "internal-video.adultempire.com" && uri.path.end_with?("/master.m3u8")
          continue.call(request)
        end
        add_cookie_to_session
        driver.get(scene_url)
        driver.find_element(xpath: '//*[@id="loadPlayer"]').click
        if player_url.nil?
          ElegantAngelDL.logger.error "Unable to find player link from player action"
          return
        end

        driver.manage.delete_all_cookies
        driver.navigate.to(player_url)
        wait.until { document_initialised(driver) }
        m3u8_link
      end
    end
  end
end
