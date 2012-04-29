require 'logger'
require 'httparty'
require 'chronic'

require 'proby/exceptions'
require 'proby/proby_http_api'
require 'proby/proby_task'
require 'proby/notifier'
require 'proby/resque_plugin'

module Proby

  # A simple library for working with the Proby task monitoring application.
  class << self

    # Set your Proby API key.
    #
    # @param [String] api_key Your Proby API key
    #
    # @example
    #   Proby.api_key = '1234567890abcdefg'
    def api_key=(api_key)
      @api_key = api_key
    end

    # Get the api key.
    def api_key
      @api_key
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
      @logger ||= Logger.new("/dev/null")
    end

    # Send a start notification for this task to Proby.
    #
    # @param [String] proby_task_id The id of the task to be notified. If nil, the
    #                               value of the +PROBY_TASK_ID+ environment variable will be used.
    #
    # @return [Fixnum] The HTTP status code that was returned from Proby.
    def send_start_notification(proby_task_id=nil)
      Notifier.send_notification('start', proby_task_id)
    end

    # Send a finish notification for this task to Proby
    #
    # @param [String] proby_task_id The id of the task to be notified. If nil, the
    #                               value of the +PROBY_TASK_ID+ environment variable will be used.
    # @param [Hash] options The options for the finish notification
    # @option options [Boolean] :failed true if this task run resulted in some sort of failure. Setting
    #                                   this parameter to true will trigger a notification to be sent to
    #                                   the alarms configured for the given task. Defaults to false.
    # @option options [String] :error_message A string message describing the failure that occurred.
    #                                         1,000 character limit.
    #
    # @return [Fixnum] The HTTP status code that was returned from Proby.
    def send_finish_notification(proby_task_id=nil, options={})
      Notifier.send_notification('finish', proby_task_id, options)
    end

    # Surround the block of code with Proby start and finish notifications.  If an exception
    # is raised in the block of code, then the task will be marked as failed, and the
    # exception's message and backtrace will be sent to Proby as the task's error message.
    #
    # @param [String] proby_task_id The id of the task to be notified. If nil, the
    #                               value of the +PROBY_TASK_ID+ environment variable will be used.
    def monitor(proby_task_id=nil)
      failed = false
      error_message = nil
      begin
        Proby.send_start_notification(proby_task_id)
        yield
      rescue Exception => e
        failed = true
        error_message = "#{e.class.name}: #{e.message}"
        error_message << "\n#{e.backtrace.join("\n")}" if e.backtrace
        raise e
      ensure
        Proby.send_finish_notification(proby_task_id, :failed => failed, :error_message => error_message)
      end
    end

  end
end

