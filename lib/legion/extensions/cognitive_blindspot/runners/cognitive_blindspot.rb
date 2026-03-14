# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveBlindspot
      module Runners
        module CognitiveBlindspot
          include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

          def register_blindspot(domain:, discovered_by:, description:,
                                 severity: nil, **)
            sev = severity || Helpers::Constants::DEFAULT_SEVERITY
            spot = engine.register_blindspot(
              domain:        domain,
              discovered_by: discovered_by,
              description:   description,
              severity:      sev
            )
            { success: true }.merge(spot.to_h)
          end

          def acknowledge_blindspot(blindspot_id:, **)
            result = engine.acknowledge_blindspot(blindspot_id: blindspot_id)
            return { success: false, error: 'blindspot not found' } unless result[:found]

            { success: true }.merge(result)
          end

          def mitigate_blindspot(blindspot_id:, boost: nil, **)
            b = boost || Helpers::Constants::SEVERITY_BOOST
            result = engine.mitigate_blindspot(blindspot_id: blindspot_id, boost: b)
            return { success: false, error: 'blindspot not found' } unless result[:found]

            { success: true }.merge(result)
          end

          def resolve_blindspot(blindspot_id:, **)
            result = engine.resolve_blindspot(blindspot_id: blindspot_id)
            return { success: false, error: 'blindspot not found' } unless result[:found]

            { success: true }.merge(result)
          end

          def set_knowledge_boundary(domain:, confidence: 0.5, coverage_estimate: 0.5, **)
            boundary = engine.set_boundary(
              domain:            domain,
              confidence:        confidence,
              coverage_estimate: coverage_estimate
            )
            { success: true }.merge(boundary.to_h)
          end

          def detect_boundary_gap(domain:, error_occurred: false, **)
            result = engine.detect_boundary_gap(domain: domain, error_occurred: error_occurred)
            { success: true }.merge(result)
          end

          def active_blindspots_report(**)
            spots = engine.active_blindspots
            { success: true, count: spots.size, blindspots: spots.map(&:to_h) }
          end

          def most_severe_report(limit: 5, **)
            spots = engine.most_severe(limit: limit)
            { success: true, limit: limit, blindspots: spots.map(&:to_h) }
          end

          def mitigation_strategies_report(domain: nil, **)
            strategies = engine.mitigation_strategies(domain: domain)
            { success: true, count: strategies.size, strategies: strategies }
          end

          def coverage_report(**)
            boundaries = engine.coverage_report
            { success: true, count: boundaries.size, boundaries: boundaries }
          end

          def johari_report(**)
            engine.johari_report
          end

          def awareness_score_report(**)
            score = engine.awareness_score
            {
              success:         true,
              awareness_score: score.round(10),
              awareness_label: engine.awareness_label,
              awareness_gap:   engine.awareness_gap
            }
          end

          def blindspot_stats(**)
            engine.to_h
          end
        end
      end
    end
  end
end
