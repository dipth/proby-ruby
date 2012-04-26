module Proby
  class ProbyHttpApi
    include HTTParty
    base_uri "https://proby.signalhq.com"
    default_timeout 5

    protected

    def self.handle_api_failure(response)
      if response.code == 401
        raise AuthFailedException.new("Authentication to Proby failed.  Make sure your API key is correct.")
      else
        message = "API request failed with a response code of #{response.code}.  Respone body: #{response.body}"
        Proby.logger.error message
        raise ApiException.new(message)
      end
    end

    def self.default_headers
      { 'api_key' => Proby.api_key, 'Content-Type' => 'application/json' }
    end

    def self.blank?(s)
      s.nil? || s.strip.empty?
    end

  end
end
