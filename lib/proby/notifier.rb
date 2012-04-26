module Proby
  class Notifier < ProbyHttpApi

    def self.send_notification(type, proby_task_id, options={})
      if Proby.api_key.nil?
        Proby.logger.warn "Proby: No notification sent because API key is not set"
        return nil
      end

      proby_task_id = ENV['PROBY_TASK_ID'] if blank?(proby_task_id)
      if blank?(proby_task_id)
        Proby.logger.warn "Proby: No notification sent because task ID was not specified"
        return nil
      end

      response = post("/api/v1/tasks/#{proby_task_id}/#{type}.json",
                      :body => MultiJson.encode(options),
                      :format => :json,
                      :headers => default_headers)
      response.code
    rescue Exception => e
      Proby.logger.error "Proby: Proby notification failed: #{e.message}"
      Proby.logger.error e.backtrace
    end

  end
end

