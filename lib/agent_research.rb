#!/usr/bin/env ruby
require "json"
require "json-schema"
require "erb"
require "date"
require "fileutils"
require "openai"

# --- Config ---
SCHEMA = {
  "type" => "object",
  "required" => %w[title problem_id region impact_estimate effort_estimate confidence summary scope rationale_bullets risks success_metrics six_week_plan sources],
  "properties" => {
    "title" => {"type" => "string"},
    "problem_id" => {"type" => "string"},
    "region" => {"type" => "string"},
    "impact_estimate" => {"enum" => ["High", "Medium", "Low"]},
    "effort_estimate" => {"enum" => ["High", "Medium", "Low"]},
    "confidence" => {"type" => "number"},
    "summary" => {"type" => "string"},
    "scope" => {"type" => "array", "items" => {"type" => "string"}},
    "rationale_bullets" => {"type" => "array", "items" => {"type" => "string"}},
    "risks" => {"type" => "array", "items" => {"type" => "string"}},
    "success_metrics" => {"type" => "array", "items" => {"type" => "string"}},
    "six_week_plan" => {"type" => "array", "items" => {"type" => "string"}},
    "sources" => {"type" => "array", "items" => {"type" => "object"}}
  }
}

TEMPLATE = ERB.new <<~MD
  ---
  id: <%= slug %>
  problem_id: <%= pitch["problem_id"] %>
  region: <%= pitch["region"] %>
  impact_estimate: <%= pitch["impact_estimate"] %>
  effort_estimate: <%= pitch["effort_estimate"] %>
  timebox_weeks: 6
  confidence: <%= sprintf("%.2f", pitch["confidence"]) %>
  owner: unassigned
  status: proposed
  created_by: bot@nightly
  updated_at: <%= Date.today.iso8601 %>
  sources:
  <% pitch["sources"].each do |s| -%>
    - title: "<%= s["title"] %>"
      url: "<%= s["url"] %>"
      accessed: "<%= s["accessed"] %>"
  <% end -%>
  ---
  
  ## Summary
  <%= pitch["summary"] %>
  
  ## Scope
  <% pitch["scope"].each do |it| -%>
  - <%= it %>
  <% end -%>
  
  ## Data / Rationale
  <% pitch["rationale_bullets"].each do |it| -%>
  - <%= it %>
  <% end -%>
  
  ## Risks & Mitigations
  <% pitch["risks"].each do |it| -%>
  - <%= it %>
  <% end -%>
  
  ## Success Metrics
  <% pitch["success_metrics"].each do |it| -%>
  - <%= it %>
  <% end -%>
  
  ## Next Steps (6-week pitch)
  <% pitch["six_week_plan"].each do |it| -%>
  - <%= it %>
  <% end -%>
MD

def slugify(str)
  str.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
end

# --- Agent Call ---
client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

system = "You are a cautious research assistant. Output ONLY JSON. Use this schema: #{SCHEMA.to_json}"

prompt = <<~PROMPT
  Region: #{ENV.fetch("REGION", "Global")}
  Problem ID: climate-change
  Today: #{Date.today.iso8601}
  
  Return 1–2 pitches.
PROMPT

resp = client.chat(
  parameters: {
    model: "gpt-4o-mini",
    response_format: {type: "json_object"},
    messages: [
      {role: "system", content: system},
      {role: "user", content: prompt}
    ]
  }
)

json_out = JSON.parse(resp.dig("choices", 0, "message", "content"))
pitches = json_out["pitches"] || []

pitches.each do |pitch|
  JSON::Validator.validate!(SCHEMA, pitch)
  slug = "#{slugify(pitch["title"])}-#{slugify(pitch["region"])}"
  out_path = File.join("pitches", "#{slug}.md")
  FileUtils.mkdir_p(File.dirname(out_path))
  File.write(out_path, TEMPLATE.result_with_hash(pitch: pitch, slug: slug))
  puts "[write] #{out_path}"
end
