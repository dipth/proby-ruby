module Proby
  class ProbyHttpApi
    include HTTParty
    base_uri "https://proby.signalhq.com"
    default_timeout 5

    def self.default_headers
      { 'api_key' => Proby.api_key, 'Content-Type' => 'application/json' }
    end
  end
end
