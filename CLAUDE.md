# lex-cognitive-blindspot

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## Purpose

Johari Window for AI. Tracks unknown-unknowns, manages knowledge boundaries, and scores agent awareness with blindspot acknowledgement and mitigation strategies. Models the progression from unknown-unknown (active blindspot) to known-unknown (acknowledged) to mitigated to resolved.

## Gem Info

- **Gem name**: `lex-cognitive-blindspot`
- **Version**: `0.1.0`
- **Module**: `Legion::Extensions::CognitiveBlindspot`
- **Ruby**: `>= 3.4`
- **License**: MIT

## File Structure

```
lib/legion/extensions/cognitive_blindspot/
  cognitive_blindspot.rb
  version.rb
  client.rb
  helpers/
    constants.rb
    blindspot.rb
    knowledge_boundary.rb
    blindspot_engine.rb
  runners/
    cognitive_blindspot.rb
```

## Key Constants

From `helpers/constants.rb`:

- `DISCOVERY_METHODS` — `%i[error_analysis peer_feedback cross_domain_check contradiction_detection confidence_calibration external_audit self_reflection unknown]`
- `MAX_BLINDSPOTS` = `300`, `MAX_BOUNDARIES` = `50`
- `DEFAULT_SEVERITY` = `0.5`, `SEVERITY_BOOST` = `0.1`
- `AWARENESS_THRESHOLD` = `0.6`
- `SEVERITY_LABELS` — `0.8+` = `:critical`, `0.6` = `:high`, `0.4` = `:moderate`, `0.2` = `:low`, below = `:negligible`
- `AWARENESS_LABELS` — `0.8+` = `:highly_aware` through below `0.2` = `:unaware`
- `COVERAGE_LABELS` — `0.8+` = `:comprehensive` through below `0.2` = `:minimal`
- `STATUS_LABELS` — describes each state: `active` = unknown-unknown, `acknowledged` = known-unknown, `mitigated` = partial coverage, `resolved` = fully addressed

## Runners

All methods in `Runners::CognitiveBlindspot`:

- `register_blindspot(domain:, discovered_by:, description:, severity: DEFAULT_SEVERITY)` — records a new blindspot in `active` state
- `acknowledge_blindspot(blindspot_id:)` — transitions from `active` to `acknowledged` (unknown-unknown -> known-unknown)
- `mitigate_blindspot(blindspot_id:, boost: SEVERITY_BOOST)` — applies mitigation; reduces severity by boost amount
- `resolve_blindspot(blindspot_id:)` — marks as fully resolved
- `set_knowledge_boundary(domain:, confidence:, coverage_estimate:)` — establishes a domain-level knowledge boundary
- `detect_boundary_gap(domain:, error_occurred: false)` — checks if errors in a domain indicate boundary gaps
- `active_blindspots_report` — all unacknowledged or unresolved blindspots
- `most_severe_report(limit: 5)` — top blindspots by severity
- `mitigation_strategies_report(domain: nil)` — recommended strategies per domain
- `coverage_report` — all knowledge boundaries with coverage estimates
- `johari_report` — full Johari Window breakdown: known-knowns, known-unknowns, unknown-unknowns counts
- `awareness_score_report` — scalar awareness score, label, and awareness gap

## Helpers

- `BlindspotEngine` — stores blindspots and knowledge boundaries; computes awareness score as ratio of acknowledged/mitigated/resolved to total.
- `Blindspot` — individual blindspot with `domain`, `discovered_by`, `description`, `severity`, `status`. State machine: `active` -> `acknowledged` -> `mitigated` -> `resolved`.
- `KnowledgeBoundary` — domain-level confidence and coverage estimate; gap detection on error events.

## Integration Points

- `lex-cognitive-debugging` detects reasoning errors; those errors are natural inputs to `register_blindspot` (via `discovered_by: :error_analysis`).
- `lex-tick` can call awareness score checks in the `identity_entropy_check` phase to flag low-awareness domains.
- `detect_boundary_gap` is meant to be called when errors occur — the caller passes `error_occurred: true` to trigger gap analysis for the relevant domain.

## Development Notes

- Blindspot state progression is one-directional: `active` -> `acknowledged` -> `mitigated` -> `resolved`. No regression.
- `awareness_score` is computed as `(acknowledged + mitigated + resolved) / total_blindspots`. An agent with no registered blindspots returns `0.0` (unaware, not aware).
- `johari_report` maps: `active` = unknown-unknown quadrant; `acknowledged/mitigated` = known-unknown quadrant; no explicit known-known tracking (that would require a separate knowledge model).
