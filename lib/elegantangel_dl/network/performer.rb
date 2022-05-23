# frozen_string_literal: true

module ElegantAngelDL
  module Network
    class Performer < Base
      attr_accessor :performer_page

      def fetch_scenes
        doc = fetch_page
        doc.css("#scenes")
           .css(".grid-item")
           .css("a")
           .map { |link| link["href"] }
           .map { |link| File.join(BASE_URL, link) }
      end

      private

      def fetch_page
        page = handle_api_resp(performer_page, HTTParty.get(performer_page, headers: default_headers))
        Nokogiri::HTML(page.body)
      end
    end
  end
end
