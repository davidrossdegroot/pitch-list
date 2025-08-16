require "uri"
require "date"

def normalize_enum(v)
  map = {"high" => "High", "medium" => "Medium", "low" => "Low"}
  map[v.to_s.strip.downcase] || "Medium"
end

def normalize_confidence(v)
  return v if v.is_a?(Numeric)
  map = {"high" => 0.85, "medium" => 0.6, "low" => 0.3}
  map[v.to_s.strip.downcase] || begin
    Float(v)
  rescue
    0.5
  end
end

def coerce_pitch!(pitch, today: Date.today.iso8601)
  # required scalars
  pitch["title"] = pitch["title"].to_s.strip
  pitch["problem_id"] = pitch["problem_id"].to_s.strip
  pitch["region"] = pitch["region"].to_s.strip

  # enums / numeric
  pitch["impact_estimate"] = normalize_enum(pitch["impact_estimate"])
  pitch["effort_estimate"] = normalize_enum(pitch["effort_estimate"])
  pitch["confidence"] = normalize_confidence(pitch["confidence"])

  # arrays: wrap strings
  %w[scope rationale_bullets risks success_metrics six_week_plan].each do |k|
    v = pitch[k]
    pitch[k] = Array(v).flatten.compact.map(&:to_s)
  end

  # sources: allow strings or objects; ensure accessed/title
  pitch["sources"] = Array(pitch["sources"]).map do |s|
    case s
    when String
      host = begin
        URI(s).host
      rescue
        nil
      end
      {"title" => host || s, "url" => s, "accessed" => today}
    when Hash
      s["title"] ||= begin
        URI(s["url"]).host
      rescue
        "source"
      end
      s["accessed"] ||= today
      s
    end
  end.compact

  # opportunities: ensure array of hashes
  pitch["opportunities"] = Array(pitch["opportunities"]).select { |o| o.is_a?(Hash) }
end
