# frozen_string_literal: true

module ElegantAngelDL
  module Network
    class Movie < Base
      attr_accessor :movie_page

      def fetch_scenes
        doc = fetch_page
        doc.css("#scenes")
           .css(".grid-item")
           .css(".scene-title")
           .css("a")
           .map { |link| link["href"] }
           .map { |link| File.join(BASE_URL, link) }
      end

      private

      def fetch_page
        page = handle_api_resp(movie_page, HTTParty.get(movie_page, headers: default_headers))
        Nokogiri::HTML(page.body)
      end
    end
  end
end
