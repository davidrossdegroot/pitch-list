require "date"
require_relative "../../lib/normalize_pitch"

RSpec.describe :coerce_pitch! do
  let(:today) { Date.new(2025, 8, 16).iso8601 }

  it "stringifies and trims title, problem_id, and region" do
    pitch = {"title" => "  My Pitch  ", "problem_id" => 123, "region" => nil}
    coerce_pitch!(pitch, today: today)

    expect(pitch["title"]).to eq("My Pitch")
    expect(pitch["problem_id"]).to eq("123")
    expect(pitch["region"]).to eq("")
  end

  it "normalizes enum estimates and defaults unknown to Medium" do
    pitch = {"impact_estimate" => "HIGH", "effort_estimate" => "unknown"}
    coerce_pitch!(pitch, today: today)

    expect(pitch["impact_estimate"]).to eq("High")
    expect(pitch["effort_estimate"]).to eq("Medium")
  end

  it "coerces confidence numbers and string numbers and falls back for invalid values" do
    p1 = {"confidence" => 0.72}
    p2 = {"confidence" => "0.42"}
    p3 = {"confidence" => "high"}
    p4 = {"confidence" => nil}

    coerce_pitch!(p1, today: today)
    coerce_pitch!(p2, today: today)
    coerce_pitch!(p3, today: today)
    coerce_pitch!(p4, today: today)

    expect(p1["confidence"]).to eq(0.72)
    expect(p2["confidence"]).to be_within(0.0001).of(0.42)
    expect(p3["confidence"]).to be_within(0.0001).of(0.85)
    expect(p4["confidence"]).to be_within(0.0001).of(0.5)
  end

  it "formats numeric confidence values to 2 decimal places" do
    p1 = {"confidence" => 0.123456789}
    p2 = {"confidence" => 0.7}
    p3 = {"confidence" => 1}
    p4 = {"confidence" => "0.999999"}

    coerce_pitch!(p1, today: today)
    coerce_pitch!(p2, today: today)
    coerce_pitch!(p3, today: today)
    coerce_pitch!(p4, today: today)

    # All should be formatted to 2 decimal places and converted back to float
    expect(p1["confidence"]).to eq(0.12)
    expect(p2["confidence"]).to eq(0.70)
    expect(p3["confidence"]).to eq(1.00)
    expect(p4["confidence"]).to eq(1.00)
  end

  it "wraps scalar array fields, flattens, removes nils and stringifies values" do
    pitch = {
      "scope" => "single",
      "rationale_bullets" => ["a", nil, :sym],
      "risks" => nil,
      "success_metrics" => [["m1", "m2"]],
      "six_week_plan" => "step1"
    }

    coerce_pitch!(pitch, today: today)

    expect(pitch["scope"]).to eq(["single"])
    expect(pitch["rationale_bullets"]).to eq(["a", "sym"])
    expect(pitch["risks"]).to eq([])
    expect(pitch["success_metrics"]).to eq(["m1", "m2"])
    expect(pitch["six_week_plan"]).to eq(["step1"])
  end

  it "normalizes string sources into hashes with title, url, and accessed" do
    pitch = {"sources" => ["http://example.com/page", "not-a-url"]}
    coerce_pitch!(pitch, today: today)

    expect(pitch["sources"]).to all(be_a(Hash))
    expect(pitch["sources"]).to include(
      a_hash_including("title" => "example.com", "url" => "http://example.com/page", "accessed" => today)
    )
    expect(pitch["sources"]).to include(a_hash_including("title" => "not-a-url", "url" => "not-a-url", "accessed" => today))
  end
end
