require_relative "../../lib/url_validator"

RSpec.describe URLValidator do
  let(:validator) { URLValidator.new }

  describe "#valid_url?" do
    it "returns true for valid HTTP URLs" do
      expect(validator.valid_url?("http://example.com")).to be true
      expect(validator.valid_url?("http://www.google.com/path?query=value")).to be true
    end

    it "returns true for valid HTTPS URLs" do
      expect(validator.valid_url?("https://example.com")).to be true
      expect(validator.valid_url?("https://subdomain.example.com/path")).to be true
    end

    it "returns false for URLs without schemes" do
      expect(validator.valid_url?("example.com")).to be false
      expect(validator.valid_url?("www.google.com")).to be false
    end

    it "returns false for malformed URLs" do
      expect(validator.valid_url?("http://")).to be false
      expect(validator.valid_url?("https://")).to be false
      expect(validator.valid_url?("not-a-url")).to be false
      expect(validator.valid_url?("http:///path")).to be false
    end

    it "returns false for nil, empty, or whitespace-only URLs" do
      expect(validator.valid_url?(nil)).to be false
      expect(validator.valid_url?("")).to be false
      expect(validator.valid_url?("   ")).to be false
    end

    it "handles URLs with different schemes appropriately" do
      expect(validator.valid_url?("ftp://example.com")).to be false
      expect(validator.valid_url?("mailto:test@example.com")).to be false
      expect(validator.valid_url?("file:///path/to/file")).to be false
    end

    it "strips whitespace from URLs before validation" do
      expect(validator.valid_url?("  https://example.com  ")).to be true
    end
  end

  describe "#government_domain?" do
    it "returns true for US government domains" do
      expect(validator.government_domain?("https://whitehouse.gov")).to be true
      expect(validator.government_domain?("http://nasa.gov")).to be true
      expect(validator.government_domain?("https://subdomain.state.gov")).to be true
    end

    it "returns true for international government domains" do
      expect(validator.government_domain?("https://canada.gc.ca")).to be true
      expect(validator.government_domain?("http://parliament.gov.uk")).to be true
      expect(validator.government_domain?("https://diplomatie.gouv.fr")).to be true
      expect(validator.government_domain?("https://presidency.gov.au")).to be true
    end

    it "returns false for non-government domains" do
      expect(validator.government_domain?("https://google.com")).to be false
      expect(validator.government_domain?("http://github.com")).to be false
      expect(validator.government_domain?("https://example.org")).to be false
    end

    it "returns false for invalid URLs" do
      expect(validator.government_domain?("not-a-url")).to be false
      expect(validator.government_domain?(nil)).to be false
      expect(validator.government_domain?("")).to be false
    end

    it "is case insensitive" do
      expect(validator.government_domain?("HTTPS://NASA.GOV")).to be true
      expect(validator.government_domain?("https://CANADA.GC.CA")).to be true
    end
  end

  describe "#fake_url?" do
    it "returns true for common fake domains" do
      expect(validator.fake_url?("http://example.com")).to be true
      expect(validator.fake_url?("https://example.org")).to be true
      expect(validator.fake_url?("http://test.com")).to be true
      expect(validator.fake_url?("https://placeholder.com")).to be true
    end

    it "returns true for localhost and local IPs" do
      expect(validator.fake_url?("http://localhost")).to be true
      expect(validator.fake_url?("https://localhost:3000")).to be true
      expect(validator.fake_url?("http://127.0.0.1")).to be true
      expect(validator.fake_url?("http://0.0.0.0")).to be true
    end

    it "returns true for private IP addresses" do
      expect(validator.fake_url?("http://192.168.1.1")).to be true
      expect(validator.fake_url?("https://10.0.0.1")).to be true
      expect(validator.fake_url?("http://172.16.0.1")).to be true
      expect(validator.fake_url?("https://172.25.255.254")).to be true
    end

    it "returns true for domains with test-related keywords" do
      expect(validator.fake_url?("http://testing.example.com")).to be true
      expect(validator.fake_url?("https://mydummysite.com")).to be true
      expect(validator.fake_url?("http://mockapi.com")).to be true
      expect(validator.fake_url?("https://sampledata.org")).to be true
    end

    it "returns false for legitimate domains" do
      expect(validator.fake_url?("https://google.com")).to be false
      expect(validator.fake_url?("http://github.com")).to be false
      expect(validator.fake_url?("https://stackoverflow.com")).to be false
      expect(validator.fake_url?("http://news.ycombinator.com")).to be false
    end

    it "returns true for malformed URLs" do
      expect(validator.fake_url?("not-a-url")).to be true
      expect(validator.fake_url?("http://")).to be true
      expect(validator.fake_url?("malformed")).to be true
    end

    it "returns true for nil or empty URLs" do
      expect(validator.fake_url?(nil)).to be true
      expect(validator.fake_url?("")).to be true
      expect(validator.fake_url?("   ")).to be true
    end

    it "is case insensitive for domain matching" do
      expect(validator.fake_url?("HTTP://EXAMPLE.COM")).to be true
      expect(validator.fake_url?("https://TEST.ORG")).to be true
    end
  end

  describe "#reachable?" do
    # Note: These tests involve actual network calls and may be unreliable
    # In a real environment, you might want to mock these or use VCR
    
    context "with valid URLs" do
      it "returns false for invalid URLs first" do
        expect(validator.reachable?("not-a-url")).to be false
        expect(validator.reachable?(nil)).to be false
      end

      # These tests may be flaky due to network conditions
      # Consider mocking in production tests
      it "handles network timeouts gracefully" do
        # This should timeout quickly due to non-routable IP
        expect(validator.reachable?("http://10.255.255.1")).to be false
      end

      it "handles SSL errors gracefully" do
        # This might cause SSL errors on some systems
        # The method should handle them gracefully
        result = validator.reachable?("https://self-signed.badssl.com")
        expect(result).to be_in([true, false]) # Either works or fails gracefully
      end
    end

    context "with localhost URLs" do
      it "returns false for unreachable localhost ports" do
        # Assuming port 99999 is not in use
        expect(validator.reachable?("http://localhost:99999")).to be false
      end
    end

    # Performance test to ensure < 5 second requirement
    it "completes within the timeout limit" do
      start_time = Time.now
      validator.reachable?("http://10.255.255.1") # Non-routable IP
      end_time = Time.now
      
      expect(end_time - start_time).to be < URLValidator::HTTP_TIMEOUT + 1
    end
  end

  describe "integration scenarios" do
    it "correctly categorizes a mix of URL types" do
      urls = [
        "https://whitehouse.gov",           # valid, government, not fake, potentially reachable
        "http://example.com",              # valid, not government, fake
        "https://google.com",              # valid, not government, not fake, likely reachable
        "not-a-url",                       # invalid, not government, fake
        "http://localhost:3000",           # valid, not government, fake
        "",                                # invalid, not government, fake
        "https://canada.gc.ca"             # valid, government, not fake, potentially reachable
      ]

      results = urls.map do |url|
        {
          url: url,
          valid: validator.valid_url?(url),
          government: validator.government_domain?(url),
          fake: validator.fake_url?(url)
        }
      end

      # Test expected patterns
      expect(results[0][:valid]).to be true    # whitehouse.gov
      expect(results[0][:government]).to be true
      expect(results[0][:fake]).to be false

      expect(results[1][:valid]).to be true    # example.com
      expect(results[1][:government]).to be false
      expect(results[1][:fake]).to be true

      expect(results[2][:valid]).to be true    # google.com
      expect(results[2][:government]).to be false
      expect(results[2][:fake]).to be false

      expect(results[3][:valid]).to be false   # not-a-url
      expect(results[3][:fake]).to be true

      expect(results[4][:valid]).to be true    # localhost:3000
      expect(results[4][:government]).to be false
      expect(results[4][:fake]).to be true
    end
  end
end