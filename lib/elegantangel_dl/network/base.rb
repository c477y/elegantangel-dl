# frozen_string_literal: true

module ElegantAngelDL
  module Network
    class Base
      include HTTParty

      BASE_URL = "https://www.elegantangel.com"

      attr_reader :driver, :wait

      def initialize(cookie_string)
        add_cookie(cookie_string)
      end

      # @param [HTTParty::Response] resp
      def handle_api_resp(endpoint, resp)
        case resp.code
        when 200 then resp
        when 400 then raise BadRequestError(endpoint: endpoint, code: 400, description: resp.parsed_response)
        else raise UnhandledError(endpoint: endpoint, code: 400, description: resp.parsed_response)
        end
      end

      def setup_browser
        @driver = Selenium::WebDriver.for :chrome
        @wait = Selenium::WebDriver::Wait.new(timeout: 10)
      end

      def close_browser
        @driver.quit
      end

      private

      def default_headers
        {
          "User-Agent" => "Mozilla/5.0 (Macintosh; Intel Mac OS X 12.4; rv:100.0) Gecko/20100101 Firefox/100.0",
          "Accept" => "*/*",
          "Connection" => "keep-alive",
          "DNT" => "1",
          "cookie" => cookie_hash.to_cookie_string
        }
      end

      def add_cookie_to_session
        # Cookie can only be added when page is loaded
        driver.get("https://www.elegantangel.com")
        cookie_hash.each_pair do |key, value|
          driver.manage.add_cookie(name: key, value: value)
        end
      end

      def add_cookie(cookie_string)
        cookie_string.split(";").map(&:strip).each { |c| cookie_hash.add_cookies(c) }
      end

      def cookie_hash
        @cookie_hash ||= HTTParty::CookieHash.new
      end
    end
  end
end
