module Proby
  # Exception raised when a request to Proby fails
  class ApiException < StandardError; end

  # Exception raised when the api key is not properly set
  class InvalidApiKeyException < StandardError; end

  # Authentication to Proby failed.  Make sure your API key is correct.
  class AuthFailedException < StandardError; end

  # An invalid parameter was passed to the given method
  class InvalidParameterException < StandardError; end
end
