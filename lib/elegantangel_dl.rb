# frozen_string_literal: true

require "colorize"
require "forwardable"
require "httparty"
require "nokogiri"
require "open3"
require "parallel"
require "selenium-webdriver"
require "set"
require "webdrivers/chromedriver"
require "yaml"

require "pry" # TODO: Remove me

module ElegantAngelDL
  class APIError < StandardError
    attr_reader :endpoint, :code, :description

    def initialize(endpoint:, code:, description:)
      @endpoint = endpoint
      @code = code
      @description = description
      super(message)
    end

    def message
      "API request to #{endpoint} failed with code #{code}. The error was: #{description}"
    end
  end

  class NotFoundError < APIError; end
  class BadRequestError < APIError; end
  class BadGatewayError < APIError; end
  class UnhandledError < APIError; end

  class ShellError < StandardError; end

  class InvalidFile < StandardError
    def initialize(file)
      super("Unable to read file #{file}. Check the path and try again.")
    end
  end

  class FatalError < StandardError; end

  def self.logger(**opts)
    @logger ||= ElegantAngelDL::Log.new(**opts).logger
  end

  def self.youtube_dl_logger
    @youtube_dl_logger ||= Logger.new("downloader.log", "daily")
  end
end

require_relative "elegantangel_dl/cli"
require_relative "elegantangel_dl/client"

require_relative "elegantangel_dl/version"
require_relative "elegantangel_dl/log"

require_relative "elegantangel_dl/data/download_status_database"
require_relative "elegantangel_dl/data/scene_data"

require_relative "elegantangel_dl/download/downloader"
require_relative "elegantangel_dl/download/base"
require_relative "elegantangel_dl/download/yt_dlp"
require_relative "elegantangel_dl/download/youtube_dl"

require_relative "elegantangel_dl/network/base"
require_relative "elegantangel_dl/network/movie"
require_relative "elegantangel_dl/network/performer"
require_relative "elegantangel_dl/network/scene"
