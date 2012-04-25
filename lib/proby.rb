require 'logger'

require 'proby/notifier'
require 'proby/resque_plugin'

module Proby

  # A simple library for working with the Proby task monitoring application.
  class << self
    include Notifier

    # Set your Proby API key.
    #
    # @param [String] api_key Your Proby API key
    #
    # @example
    #   Proby.api_key = '1234567890abcdefg'
    def api_key=(api_key)
      @api_key = api_key
    end

    # Set the logger to be used by Proby.
    #
    # @param [Logger] logger The logger you would like Proby to use
    #
    # @example
    #   Proby.logger = Rails.logger
    #   Proby.logger = Logger.new(STDERR)
    def logger=(logger)
      @logger = logger
    end

    # Get the logger used by Proby.
    def logger
      @logger || Logger.new("/dev/null")
    end
  end
end

