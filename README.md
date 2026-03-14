# lex-cognitive-blindspot

Cognitive blindspot detection for LegionIO agents. Johari Window for AI — tracks unknown-unknowns, manages knowledge boundaries, and scores agent awareness with blindspot acknowledgement and mitigation strategies.

## What It Does

Models the progression from unknown-unknown (active blindspot: the agent doesn't know what it doesn't know) to known-unknown (acknowledged: now visible but not addressed) to mitigated (partial coverage) to resolved. Discovery methods include error analysis, peer feedback, contradiction detection, confidence calibration, and self-reflection.

A parallel knowledge boundary system tracks domain-level confidence and coverage estimates, with gap detection triggered by error events in a domain.

## Usage

```ruby
client = Legion::Extensions::CognitiveBlindspot::Client.new

spot = client.register_blindspot(
  domain: :temporal_reasoning,
  discovered_by: :error_analysis,
  description: 'Consistently misjudges elapsed time in multi-step plans',
  severity: 0.7
)

client.acknowledge_blindspot(blindspot_id: spot[:id])
client.mitigate_blindspot(blindspot_id: spot[:id], boost: 0.15)

client.johari_report
client.awareness_score_report
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
