#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "json-schema"
require "erb"
require "date"
require "fileutils"
require "securerandom"
require "net/http"
require "uri"
require "dotenv/load"
require "byebug"
require_relative "normalize_pitch"

# ---------- config ----------
REGION = ENV.fetch("REGION", "Global")
OPENAI_API_KEY = ENV.fetch("OPENAI_API_KEY")

MODEL = ENV.fetch("OPENAI_MODEL", "gpt-4o-mini") # any model that supports tool-calling is fine

PITCH_SCHEMA = {
  "type" => "object",
  "required" => %w[title problem_id region impact_estimate effort_estimate confidence summary scope rationale_bullets risks success_metrics six_week_plan sources opportunities],
  "properties" => {
    # ...existing...
    "opportunities" => {
      "type" => "array",
      "minItems" => 1,
      "items" => {
        "type" => "object",
        "required" => %w[type name url],
        "properties" => {
          "type" => {"enum" => ["grant", "rfp", "challenge", "rebate", "pilot", "procurement", "other"]},
          "name" => {"type" => "string"},
          "url" => {"type" => "string"},
          "sponsor" => {"type" => "string"},
          "amount" => {"type" => "string"},     # keep string to avoid currency parsing headaches
          "deadline" => {"type" => "string"},     # ISO-8601 or human; you can tighten later
          "eligibility" => {"type" => "string"},
          "notes" => {"type" => "string"}
        }
      }
    }
  }
}

# If you prefer strict JSON at the end (no tool calls), set RESPONSE_FORMAT to force JSON
RESPONSE_FORMAT = {"type" => "json_object"}

TEMPLATE = ERB.new <<~MD
  ---
  id: <%= slug %>
  problem_id: <%= pitch["problem_id"] %>
  region: <%= pitch["region"] %>
  impact_estimate: <%= pitch["impact_estimate"] %>
  effort_estimate: <%= pitch["effort_estimate"] %>
  timebox_weeks: 6
  confidence: <%= pitch["confidence"] %>
  owner: unassigned
  status: proposed
  created_by: bot@nightly
  updated_at: <%= Date.today.iso8601 %>
  sources:
  <% pitch["sources"].each do |s| %>
  - title: "<%= s["title"] %>"
    url: "<%= s["url"] %>"
    accessed: "<%= s["accessed"] %>"
  <% end %>
  ---

  ## Summary
  <%= pitch["summary"] %>

  ## Scope
  <% (pitch["scope"] || []).each do |it| %>
  - <%= it %>
  <% end %>

  ## Data / Rationale
  <% (pitch["rationale_bullets"] || []).each do |it| %>
  - <%= it %>
  <% end %>

  ## Risks & Mitigations
  <% (pitch["risks"] || []).each do |it| %>
  - <%= it %>
  <% end %>

  ## Success Metrics
  <% (pitch["success_metrics"] || []).each do |it| %>
  - <%= it %>
  <% end %>

  ## Opportunities (region-specific)
  <% (pitch["opportunities"] || []).each do |o| %>
  - **<%= o["type"] %>**: <%= o["name"] %> — <%= o["sponsor"] %><% if o["amount"] %> (Amount: <%= o["amount"] %>)<% end %><% if o["deadline"] %> — *Deadline:* <%= o["deadline"] %><% end %>
    - Link: <%= o["url"] %><% if o["eligibility"] %>
    - Eligibility: <%= o["eligibility"] %><% end %><% if o["notes"] %>
    - Notes: <%= o["notes"] %><% end %>
  <% end %>

  ## Next Steps (6-week pitch)
  <% (pitch["six_week_plan"] || []).each do |it| %>
  - <%= it %>
  <% end %>
MD

def slugify(str)
  str.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
end

def http_json(uri, headers: {}, body: nil, method: :get)
  u = URI(uri)
  http = Net::HTTP.new(u.host, u.port)
  http.use_ssl = (u.scheme == "https")
  req = case method
  when :post then Net::HTTP::Post.new(u)
  else Net::HTTP::Get.new(u)
  end
  headers.each { |k, v| req[k] = v }
  req.body = body if body
  res = http.request(req)
  [res.code.to_i, res.body]
end

def openai_chat(messages:, tools: nil, tool_choice: nil, response_format: nil)
  url = "https://api.openai.com/v1/chat/completions"
  headers = {"Authorization" => "Bearer #{OPENAI_API_KEY}", "Content-Type" => "application/json"}
  payload = {
    model: MODEL,
    temperature: 0.2,
    messages: messages
  }
  payload[:tools] = tools if tools
  payload[:tool_choice] = tool_choice if tool_choice
  payload[:response_format] = response_format if response_format
  code, body = http_json(url, headers: headers, body: payload.to_json, method: :post)
  raise "OpenAI error #{code}: #{body}" unless code.between?(200, 299)
  JSON.parse(body)
end

# --- simple “tools” the model can call ---
TOOLS = [
  {
    "type" => "function",
    "function" => {
      "name" => "web_search",
      "description" => "Search the web for recent, reputable sources. Return a short list of URLs.",
      "parameters" => {
        "type" => "object",
        "properties" => {
          "query" => {"type" => "string"},
          "region" => {"type" => "string"}
        },
        "required" => ["query", "region"]
      }
    }
  },
  {
    "type" => "function",
    "function" => {
      "name" => "http_get",
      "description" => "Fetch the contents of a URL (HTML/text). Returns first ~8000 chars.",
      "parameters" => {
        "type" => "object",
        "properties" => {
          "url" => {"type" => "string"}
        },
        "required" => ["url"]
      }
    }
  }
]

def run_with_tools(messages)
  # First pass: allow the model to call tools
  resp = openai_chat(messages: messages, tools: TOOLS, tool_choice: "auto")

  loop do
    msg = resp.dig("choices", 0, "message") || {}
    calls = msg["tool_calls"] || []

    # Always append the assistant message we just received
    messages << msg

    break if calls.empty?

    # For each tool call, run the function locally and append a tool message
    calls.each do |tc|
      name = tc.dig("function", "name")
      args = begin
        JSON.parse(tc.dig("function", "arguments") || "{}")
      rescue
        {}
      end
      result = tool_invoke(name, args)  # must return a String
      messages << {
        role: "tool",
        tool_call_id: tc["id"],
        name: name,
        content: result # String; JSON string is fine too
      }
    end

    # Ask the model again, still allowing tools (it may chain)
    resp = openai_chat(messages: messages, tools: TOOLS, tool_choice: "auto")
  end

  # Finalization pass: force strict JSON output (no tools now)
  finalize = openai_chat(
    messages: messages + [
      {role: "system", content: <<~SYS
        Output ONLY valid JSON with this exact top-level shape:
         {"pitches":[<pitch>, ...]}
         Do not output a single pitch at the top level; wrap it under "pitches".
      SYS
    }
    ],
    response_format: {type: "json_object"}
  )

  [messages, finalize]
end

def tool_invoke(name, args)
  case name
  when "web_search"
    q = "#{args["query"]} #{args["region"]}"
    warn "[web_search] #{q}"
    # At this point, plug in your search API if you want.
    # For now, just return a placeholder JSON array with the query text.
    [{query: q, note: "real URLs would go here"}].to_json
  when "http_get"
    url = args["url"]
    warn "[http_get] #{url}"
    code, body = http_json(url)
    body = body.to_s[0, 8000]
    {code: code, body: body}.to_json
  else
    raise "Unknown tool: #{name}"
  end
end

def render_markdown(pitch)
  slug = "#{slugify(pitch["title"])}-#{slugify(pitch["region"])}"
  begin
    TEMPLATE.result_with_hash(pitch: pitch, slug: slug)
  rescue => e
    # Log a concise, useful message and return nil so caller can decide how to proceed
    warn "[render_markdown] error rendering pitch #{slug}: #{e.class}: #{e.message}"
    begin
      # Truncate pitch JSON to avoid huge logs
      pitch_json = JSON.generate(pitch)
      warn "[render_markdown] pitch #{pitch_json}"
    rescue
      warn "[render_markdown] (unable to serialize pitch for logging)"
    end
    warn e.backtrace.take(6).join("\n")
    nil
  end
end

def write_pitch(pitch, out_dir: "pitches")
  slug = "#{slugify(pitch["title"])}-#{slugify(pitch["region"])}"
  path = File.join(out_dir, "#{slug}.md")
  FileUtils.mkdir_p(File.dirname(path))
  content = render_markdown(pitch)
  if content.nil?
    warn "[skip] not writing #{path} because render_markdown failed"
    return nil
  end

  File.write(path, content)
  path
end

# ---------- run ----------
problems = Dir.glob("problems/**/problem.md").map do |p|
  id = File.read(p)[/\bid:\s*([a-zA-Z0-9\-_]+)/, 1]
  {"id" => id, "path" => p} if id
end.compact

if problems.empty?
  warn "[info] no problems found"
  exit 0
end

today = Date.today.iso8601

system_prompt = <<~SYS
  You are a cautious research agent generating region-specific 6-week project pitches.

  Return ONLY JSON with shape:
  {"pitches":[<pitch>, ...]}

  Each <pitch> MUST conform to this JSON schema:
  #{JSON.pretty_generate(PITCH_SCHEMA)}

  Rules:
  - Include "problem_id" and "region" exactly as given in the task.
  - Cite at least 2 reputable, recent sources per pitch.
  - Prefer 6-week projects with clear deliverables and success metrics.
  - Output strictly valid JSON. No extra commentary.
  Additional rules:
  - Proactively search for **opportunities** in the region: grants, RFPs, challenges, rebates, pilots, procurement notices.
  - Each pitch MUST include an "opportunities" array (≥1) with fields:
    type, name, url, and when available: sponsor, amount, deadline, eligibility, notes.
  - Favor opportunities with upcoming deadlines or active cycles; include "deadline".
SYS

messages = [{role: "system", content: system_prompt}]

problems.each do |pr|
  current_problem_id = pr["id"]
  today = Date.today.iso8601

  system_prompt = <<~SYS
    You are a cautious research agent generating region-specific 6-week project pitches.
    Return ONLY JSON at the end. During reasoning you may call tools. Schema:
    #{JSON.pretty_generate(PITCH_SCHEMA)}
    Rules:
    - Include "problem_id" and "region" exactly as provided.
    - ≥ 2 recent, relevant sources per pitch.
  SYS

  user_prompt = <<~USR
    Region: #{REGION}
    Problem ID: #{current_problem_id}
    Date: #{today}

    Task: Search for **opportunities** (grants/RFPs/challenges/rebates/pilots) in this region that map to this problem,
    then produce 1–3 pitches. Each pitch must include ≥2 supporting sources AND at least one opportunity in "opportunities".
  USR

  messages = [
    {role: "system", content: system_prompt},
    {role: "user", content: user_prompt}
  ]

  _msgs, resp = run_with_tools(messages)
  content = resp.dig("choices", 0, "message", "content").to_s
  data = begin
    JSON.parse(content)
  rescue
    {}
  end
  pitches = Array(data["pitches"])
  pitches.each do |pitch|
    pitch["problem_id"] ||= current_problem_id
    pitch["region"] ||= REGION
    coerce_pitch!(pitch, today: today)
    JSON::Validator.validate!(PITCH_SCHEMA, pitch)
    path = write_pitch(pitch)
    puts "[write] #{path}"
  rescue JSON::Schema::ValidationError => e
    warn "[reject] schema error (#{current_problem_id}): #{e.message}"
    warn "[debug] pitch:\n#{JSON.pretty_generate(pitch)}" if ENV["DEBUG"] == "1"
  end
end
