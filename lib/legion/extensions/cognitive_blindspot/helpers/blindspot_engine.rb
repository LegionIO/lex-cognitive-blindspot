# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveBlindspot
      module Helpers
        class BlindspotEngine
          include Constants

          attr_reader :awareness_score

          def initialize
            @blindspots      = {}
            @boundaries      = {}
            @awareness_score = 1.0
          end

          def register_blindspot(domain:, discovered_by:, description:, severity: DEFAULT_SEVERITY)
            prune_blindspots_if_needed
            blindspot = Blindspot.new(domain: domain, discovered_by: discovered_by,
                                      description: description, severity: severity)
            @blindspots[blindspot.id] = blindspot
            recalculate_awareness
            blindspot
          end

          def acknowledge_blindspot(blindspot_id:)
            blindspot = @blindspots.fetch(blindspot_id, nil)
            return { found: false, blindspot_id: blindspot_id } unless blindspot

            blindspot.acknowledge!
            recalculate_awareness
            { found: true, blindspot_id: blindspot_id, status: blindspot.status,
              awareness_score: @awareness_score.round(10) }
          end

          def mitigate_blindspot(blindspot_id:, boost: SEVERITY_BOOST)
            blindspot = @blindspots.fetch(blindspot_id, nil)
            return { found: false, blindspot_id: blindspot_id } unless blindspot

            blindspot.mitigate!(boost: boost)
            recalculate_awareness
            { found: true, blindspot_id: blindspot_id, status: blindspot.status,
              severity: blindspot.severity, awareness_score: @awareness_score.round(10) }
          end

          def resolve_blindspot(blindspot_id:)
            blindspot = @blindspots.fetch(blindspot_id, nil)
            return { found: false, blindspot_id: blindspot_id } unless blindspot

            blindspot.resolve!
            recalculate_awareness
            { found: true, blindspot_id: blindspot_id, status: blindspot.status,
              awareness_score: @awareness_score.round(10) }
          end

          def set_boundary(domain:, confidence: 0.5, coverage_estimate: 0.5)
            prune_boundaries_if_needed
            existing = boundary_for_domain(domain)
            return update_boundary!(existing, confidence, coverage_estimate) if existing

            boundary = KnowledgeBoundary.new(domain: domain, confidence: confidence,
                                             coverage_estimate: coverage_estimate)
            @boundaries[boundary.id] = boundary
            boundary
          end

          def detect_boundary_gap(domain:, error_occurred: false)
            boundary = boundary_for_domain(domain)
            return { gap_detected: false, domain: domain, reason: :no_boundary } unless boundary

            { gap_detected: boundary.gap_detected?(error_occurred: error_occurred),
              domain: domain, confidence: boundary.confidence,
              coverage: boundary.coverage_estimate }
          end

          def blindspots_by_domain(domain)
            d = domain.to_sym
            @blindspots.values.select { |b| b.domain == d }
          end

          def active_blindspots       = @blindspots.values.select(&:active?)
          def acknowledged_blindspots = @blindspots.values.select { |b| b.status == :acknowledged }
          def resolved_blindspots     = @blindspots.values.select(&:resolved?)

          def most_severe(limit: 5)
            @blindspots.values.sort_by { |b| -b.severity }.first(limit)
          end

          def mitigation_strategies(domain: nil)
            spots = domain ? blindspots_by_domain(domain) : @blindspots.values
            spots.select(&:active?).map do |b|
              { blindspot_id: b.id, domain: b.domain, severity: b.severity, strategy: strategy_for(b) }
            end
          end

          def coverage_report  = @boundaries.values.map(&:to_h)
          def awareness_label  = Constants.label_for(AWARENESS_LABELS, @awareness_score) || :unaware
          def awareness_gap    = (1.0 - @awareness_score).clamp(0.0, 1.0).round(10)

          def johari_report
            { total_blindspots:   @blindspots.size,
              active:             active_blindspots.size,
              acknowledged:       acknowledged_blindspots.size,
              resolved:           resolved_blindspots.size,
              awareness_score:    @awareness_score.round(10),
              awareness_label:    awareness_label,
              awareness_gap:      awareness_gap,
              boundaries_tracked: @boundaries.size,
              most_severe:        most_severe(limit: 3).map(&:to_h) }
          end

          def to_h
            { total_blindspots: @blindspots.size,
              active:           active_blindspots.size,
              acknowledged:     acknowledged_blindspots.size,
              resolved:         resolved_blindspots.size,
              awareness_score:  @awareness_score.round(10),
              awareness_label:  awareness_label }
          end

          private

          def update_boundary!(boundary, confidence, coverage_estimate)
            boundary.update_confidence!(confidence)
            boundary.update_coverage!(coverage_estimate)
            boundary
          end

          def boundary_for_domain(domain)
            d = domain.to_sym
            @boundaries.values.find { |b| b.domain == d }
          end

          def recalculate_awareness
            total = @blindspots.size.to_f
            return @awareness_score = 1.0 if total.zero?

            not_active = @blindspots.values.count { |b| !b.active? }.to_f
            @awareness_score = (not_active / total).clamp(0.0, 1.0).round(10)
          end

          def strategy_for(blindspot)
            case blindspot.severity
            when (0.8..) then :immediate_external_audit
            when (0.6...0.8) then :cross_domain_check
            when (0.4...0.6) then :peer_feedback
            else :self_reflection
            end
          end

          def prune_blindspots_if_needed
            return if @blindspots.size < MAX_BLINDSPOTS

            target = resolved_blindspots.min_by(&:created_at) ||
                     @blindspots.values.min_by(&:severity)
            @blindspots.delete(target.id) if target
          end

          def prune_boundaries_if_needed
            return if @boundaries.size < MAX_BOUNDARIES

            oldest = @boundaries.values.min_by(&:created_at)
            @boundaries.delete(oldest.id) if oldest
          end
        end
      end
    end
  end
end
