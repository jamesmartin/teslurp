require "date"
require "io/console"
require "logger"
require "optparse"
require "tesla_api"

class TokenService
  # Fetches, caches and refreshes OAuth tokens for the Tesla API.
  # {
  #  "access_token": "abc123",
  #  "token_type": "bearer",
  #  "expires_in": 3888000,
  #  "refresh_token": "cba321",
  #  "created_at": 1538359034
  # }
  #
  attr_reader :client_id, :client_secret, :logger

  def initialize(client_id:, client_secret:, logger: Logger.new(STDOUT))
    @client_id = client_id
    @client_secret = client_secret
    @logger = logger
  end

  def token
    if cached_response.empty?
      logger.info("No cached token available")
      print "Email: "
      email = gets
      password = STDIN.getpass("Password:")

      client = TeslaApi::Client.new(
        email: email,
        client_id: client_id,
        client_secret: client_secret,
      )

      response = client.login!(password)
      write_cache!(response)
      return response["access_token"]
    else
      logger.info("Using token from cache...")
      if token_expired?(cached_response)
        logger.info("Token has expired, refreshing...")
        client = TeslaApi::Client.new(
          refresh_token: cached_response["refresh_token"],
          client_id: client_id,
          client_secret: client_secret,
        )
        response = client.refresh_access_token
        write_cache!(response)
        return response["access_token"]
      else
        logger.info("Token still valid until #{expires_at(cached_response)}:")
        return cached_response["access_token"]
      end
    end
  end

  def cache_file
    @cache_file ||= File.join(File.dirname(__FILE__), "tesla-api-token-response.cache")
  end

  def write_cache!(response)
    return if response.nil?

    begin
      File.open(cache_file, "w+") do |f|
        f.puts(Marshal.dump(response))
      end
    rescue Errno::ENOENT
      return response
    end
  end

  def token_expired?(response)
    expires_at(response) <= DateTime.now
  end

  def expires_at(response)
    Time.at(response["created_at"].to_f + response["expires_in"].to_f).to_datetime
  end

  def cached_response
    @cached_response ||=
      begin
        Marshal.load(File.read(cache_file))
      rescue Errno::ENOENT
        {}
      end
  end
end

if __FILE__ == $0
  puts TokenService.new(client_id: ENV["CLIENT_ID"], client_secret: ENV["CLIENT_SECRET"]).token
end
