# frozen_string_literal: true

require "thor"

module ElegantAngelDL
  class Cli < Thor
    def self.exit_on_failure?
      true
    end

    desc "version", "app version"
    def version
      require_relative "version"
      puts "v#{ElegantAngelDL::VERSION}"
    end
    map %w[--version -v] => :version

    desc "download", "Bulk download files"
    long_desc <<-LONGDESC
    `elegantangel_dl download --cookie="./cookie.txt"`#{" "}

    > $ elegantangel_dl download --cookie="./cookie.txt" --performers="./performers.yml"
    LONGDESC
    option :help, alias: :h, type: :boolean, default: false
    option :cookie, required: true, desc: "Path to the file where the cookie is stored", aliases: :c
    option :performers, required: false, desc: "Path to a YAML file with list of pages of performers", aliases: :p
    option :movies, required: false, desc: "Path to a YAML file with list of pages of movies", aliases: :m
    option :scenes, required: false, desc: "Path to a YAML file with list of pages of individual scenes", aliases: :s
    option :download_path, required: false, desc: "Directory where the files should be downloaded", aliases: :d
    option :verbose, type: :boolean, default: false, desc: "Flag to print verbose logs"
    def download
      client = Client.new(
        cookie_file: options[:cookie],
        verbose: options[:verbose],
        performer_file: options[:performers],
        movie_file: options[:movies],
        scene_file: options[:scenes],
        download_dir: options[:download_path]
      )
      client.start
    rescue Interrupt
      say "Exiting...", :green
    end
  end
end
