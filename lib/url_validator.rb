require "uri"
require "net/http"
require "timeout"

class URLValidator
  # Timeout for HTTP requests in seconds
  HTTP_TIMEOUT = 5

  # Known fake/placeholder domains
  FAKE_DOMAINS = %w[
    example.com
    example.org
    example.net
    test.com
    localhost
    127.0.0.1
    0.0.0.0
    placeholder.com
    dummy.com
    fake.com
    mock.com
    sample.com
    testing.com
  ].freeze

  # Government domain suffixes
  GOVERNMENT_SUFFIXES = %w[
    .gov
    .gov.uk
    .gc.ca
    .gov.au
    .gouv.fr
    .gob.es
    .governo.it
    .gov.br
  ].freeze

  def initialize
    # Instance variables for caching if needed in the future
  end

  # Check if URL has valid format
  def valid_url?(url)
    return false if url.nil? || url.to_s.strip.empty?

    begin
      uri = URI.parse(url.to_s.strip)
      # Must have a scheme (http/https) and host
      uri.is_a?(URI::HTTP) && !uri.host.nil? && !uri.host.empty?
    rescue URI::InvalidURIError
      false
    end
  end

  # Check if URL is reachable via HTTP request
  def reachable?(url)
    return false unless valid_url?(url)

    begin
      uri = URI.parse(url.to_s.strip)
      
      Timeout.timeout(HTTP_TIMEOUT) do
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
          request = Net::HTTP::Head.new(uri.path.empty? ? "/" : uri.path)
          response = http.request(request)
          
          # Consider 2xx and 3xx as reachable
          response.code.to_i.between?(200, 399)
        end
      end
    rescue StandardError
      # Catch all network errors, timeouts, SSL errors, etc.
      false
    end
  end

  # Check if URL belongs to a government domain
  def government_domain?(url)
    return false unless valid_url?(url)

    begin
      uri = URI.parse(url.to_s.strip)
      host = uri.host.downcase
      
      GOVERNMENT_SUFFIXES.any? { |suffix| host.end_with?(suffix) }
    rescue StandardError
      false
    end
  end

  # Check if URL appears to be fake/placeholder
  def fake_url?(url)
    return true unless valid_url?(url)

    begin
      uri = URI.parse(url.to_s.strip)
      host = uri.host.downcase
      
      # Check against known fake domains
      FAKE_DOMAINS.include?(host) ||
        # Check for localhost variations
        host.start_with?("localhost") ||
        # Check for IP addresses that are local/private
        host.match?(/^192\.168\./) ||
        host.match?(/^10\./) ||
        host.match?(/^172\.(1[6-9]|2[0-9]|3[0-1])\./) ||
        # Check for common test patterns
        host.include?("test") ||
        host.include?("example") ||
        host.include?("placeholder") ||
        host.include?("dummy") ||
        host.include?("fake") ||
        host.include?("mock") ||
        host.include?("sample")
    rescue StandardError
      true # If we can't parse it, consider it fake
    end
  end
end