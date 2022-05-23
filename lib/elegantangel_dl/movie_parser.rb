# frozen_string_literal: true

module ElegantAngelDL
  class MovieParser
    attr_reader :file

    # @param [String] file
    def initialize(file)
      @file = file
    end

    def load
      raise
    end

    def valid_file?
      File.file?(file) && File.exist?(file)
    end
  end
end
