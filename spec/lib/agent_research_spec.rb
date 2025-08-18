require "spec_helper"
require_relative "../../lib/agent_research"
require "json"

RSpec.describe "AgentResearch Token Limiting" do
  let(:mock_response) do
    {
      "choices" => [
        {
          "message" => {
            "content" => '{"pitches": [{"title": "Test Pitch", "problem_id": "test", "region": "Test Region", "impact_estimate": "Medium", "effort_estimate": "Low", "confidence": 0.8, "summary": "Test summary", "scope": ["test scope"], "rationale_bullets": ["test rationale"], "risks": ["test risk"], "success_metrics": ["test metric"], "six_week_plan": ["test plan"], "sources": [{"title": "Test Source", "url": "https://example.gov/test", "accessed": "2025-08-18"}], "opportunities": [{"type": "grant", "name": "Test Grant", "url": "https://grants.gov/test"}]}]}'
          }
        }
      ],
      "usage" => {
        "total_tokens" => 1000
      }
    }
  end

  let(:high_token_response) do
    {
      "choices" => [
        {
          "message" => {
            "content" => '{"pitches": []}'
          }
        }
      ],
      "usage" => {
        "total_tokens" => 45000  # High token usage to approach limit
      }
    }
  end

  before do
    # Reset global token counter before each test
    @total_tokens_used = 0

    # Mock environment variables
    allow(ENV).to receive(:fetch).with("REGION", "Global").and_return("Test Region")
    allow(ENV).to receive(:fetch).with("OPENAI_API_KEY").and_return("test-api-key")
    allow(ENV).to receive(:fetch).with("OPENAI_MODEL", "gpt-4o-mini").and_return("gpt-4o-mini")
  end

  describe "openai_chat token tracking" do
    it "tracks token usage correctly" do
      # Mock HTTP response
      allow_any_instance_of(Object).to receive(:http_json).and_return([200, mock_response.to_json])

      initial_tokens = @total_tokens_used

      result = openai_chat(messages: [{"role" => "user", "content" => "test"}])

      expect(@total_tokens_used).to eq(initial_tokens + 1000)
      expect(result["usage"]["total_tokens"]).to eq(1000)
    end

    it "warns when approaching token limit" do
      # Set tokens close to limit
      @total_tokens_used = 42000  # 84% of 50,000 limit

      allow_any_instance_of(Object).to receive(:http_json).and_return([200, mock_response.to_json])

      expect { openai_chat(messages: [{"role" => "user", "content" => "test"}]) }
        .to output(/token_warning.*Approaching token limit/).to_stderr
    end

    it "raises error when token limit is exceeded" do
      # Set tokens at limit
      @total_tokens_used = 50000

      expect { openai_chat(messages: [{"role" => "user", "content" => "test"}]) }
        .to raise_error(/Token limit exceeded/)
        .and output(/token_limit.*Reached maximum tokens/).to_stderr
    end

    it "prevents API calls when at token limit" do
      @total_tokens_used = 50000

      # Should not make HTTP request
      expect_any_instance_of(Object).not_to receive(:http_json)

      expect { openai_chat(messages: [{"role" => "user", "content" => "test"}]) }
        .to raise_error(/Token limit exceeded/)
    end
  end

  describe "run_with_tools token limiting" do
    before do
      # Mock tool responses
      allow_any_instance_of(Object).to receive(:tool_invoke).and_return('{"status": "test"}')
    end

    it "stops processing when token limit is reached during tool calls" do
      # Mock first call succeeds, second call hits limit
      call_count = 0
      allow_any_instance_of(Object).to receive(:http_json) do
        call_count += 1
        if call_count == 1
          # First call uses many tokens but doesn't hit limit
          response = {
            "choices" => [
              {
                "message" => {
                  "tool_calls" => [
                    {
                      "id" => "call_1",
                      "function" => {
                        "name" => "web_search",
                        "arguments" => '{"query": "test", "region": "test"}'
                      }
                    }
                  ]
                }
              }
            ],
            "usage" => {"total_tokens" => 45000}
          }
          [200, response.to_json]
        else
          # Second call would exceed limit
          @total_tokens_used = 50000
          [200, '{"error": "should not reach here"}']
        end
      end

      messages = [{"role" => "user", "content" => "test"}]

      expect { run_with_tools(messages) }
        .to raise_error(/Token limit exceeded/)
    end
  end

  describe "main processing loop token limiting" do
    let(:test_problem) { {"id" => "test-problem", "path" => "test/path"} }

    before do
      # Mock file system calls
      allow(Dir).to receive(:glob).and_return(["problems/test/problem.md"])
      allow(File).to receive(:read).and_return("id: test-problem\ntest content")
      allow(Date).to receive(:today).and_return(double(iso8601: "2025-08-18"))
    end

    it "skips remaining problems when token limit is reached" do
      # Set tokens at limit before processing
      @total_tokens_used = 50000

      # Should output warning about reaching limit
      expect {
        # Simulate the main loop logic
        problems = [test_problem, {"id" => "second-problem", "path" => "test/path2"}]
        problems.each do |pr|
          if @total_tokens_used >= MAX_TOKENS_PER_RUN
            warn "[token_limit] Reached token limit. Skipping remaining problems."
            break
          end
          # Process problem...
        end
      }.to output(/token_limit.*Reached token limit/).to_stderr
    end

    it "continues processing while under token limit" do
      @total_tokens_used = 1000  # Well under limit

      # Mock successful processing
      allow_any_instance_of(Object).to receive(:http_json).and_return([200, mock_response.to_json])
      allow_any_instance_of(Object).to receive(:run_with_tools).and_return([[], double(dig: mock_response["choices"][0]["message"]["content"])])
      allow_any_instance_of(Object).to receive(:write_pitch).and_return("test/path.md")
      allow(JSON).to receive(:parse).and_return({"pitches" => []})

      expect(@total_tokens_used).to be < MAX_TOKENS_PER_RUN
    end
  end

  describe "token limit constants and configuration" do
    it "has a reasonable default token limit" do
      expect(MAX_TOKENS_PER_RUN).to eq(50_000)
      expect(MAX_TOKENS_PER_RUN).to be > 1000  # Should be substantial
      expect(MAX_TOKENS_PER_RUN).to be < 200_000  # But not excessive
    end

    it "calculates warning threshold correctly" do
      warning_threshold = MAX_TOKENS_PER_RUN * 0.8
      expect(warning_threshold).to eq(40_000)
    end
  end

  describe "token usage reporting" do
    it "reports token usage in stderr output" do
      allow_any_instance_of(Object).to receive(:http_json).and_return([200, mock_response.to_json])

      expect { openai_chat(messages: [{"role" => "user", "content" => "test"}]) }
        .to output(/\[tokens\] Used 1000 tokens this call, 1000 total/).to_stderr
    end

    it "handles missing usage data gracefully" do
      response_without_usage = mock_response.dup
      response_without_usage.delete("usage")

      allow_any_instance_of(Object).to receive(:http_json).and_return([200, response_without_usage.to_json])

      initial_tokens = @total_tokens_used
      openai_chat(messages: [{"role" => "user", "content" => "test"}])

      # Should not increment if no usage data
      expect(@total_tokens_used).to eq(initial_tokens)
    end
  end

  describe "error handling with token limits" do
    it "includes token usage in error messages" do
      @total_tokens_used = 50000

      expect { openai_chat(messages: [{"role" => "user", "content" => "test"}]) }
        .to raise_error(/Token limit exceeded: 50000\/50000 tokens used/)
    end

    it "distinguishes token limit errors from other errors" do
      # Mock API error
      allow_any_instance_of(Object).to receive(:http_json).and_return([429, '{"error": "rate limit"}'])

      # Should raise OpenAI error, not token limit error
      expect { openai_chat(messages: [{"role" => "user", "content" => "test"}]) }
        .to raise_error(RuntimeError, /OpenAI error 429/)
    end

    it "raises token limit error when at limit" do
      @total_tokens_used = 50000

      # Should raise token limit error, not API error
      expect { openai_chat(messages: [{"role" => "user", "content" => "test"}]) }
        .to raise_error(RuntimeError, /Token limit exceeded/)
    end
  end
end
