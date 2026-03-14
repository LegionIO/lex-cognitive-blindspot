# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveBlindspot
      module Helpers
        module Constants
          MAX_BLINDSPOTS  = 300
          MAX_BOUNDARIES  = 50
          DEFAULT_SEVERITY = 0.5
          SEVERITY_BOOST   = 0.1
          AWARENESS_THRESHOLD = 0.6

          DISCOVERY_METHODS = %i[
            error_analysis peer_feedback cross_domain_check
            contradiction_detection confidence_calibration
            external_audit self_reflection unknown
          ].freeze

          SEVERITY_LABELS = {
            (0.8..)     => :critical,
            (0.6...0.8) => :high,
            (0.4...0.6) => :moderate,
            (0.2...0.4) => :low,
            (..0.2)     => :negligible
          }.freeze

          AWARENESS_LABELS = {
            (0.8..)     => :highly_aware,
            (0.6...0.8) => :aware,
            (0.4...0.6) => :partially_blind,
            (0.2...0.4) => :mostly_blind,
            (..0.2)     => :unaware
          }.freeze

          COVERAGE_LABELS = {
            (0.8..)     => :comprehensive,
            (0.6...0.8) => :substantial,
            (0.4...0.6) => :partial,
            (0.2...0.4) => :limited,
            (..0.2)     => :minimal
          }.freeze

          STATUS_LABELS = {
            active:       'Unknown unknown — not yet surfaced to awareness',
            acknowledged: 'Known unknown — surfaced, not yet mitigated',
            mitigated:    'Known unknown — mitigated with partial coverage',
            resolved:     'Known unknown — fully addressed'
          }.freeze

          def self.label_for(labels, value)
            match = labels.find { |range, _| range.cover?(value) }
            match&.last
          end
        end
      end
    end
  end
end
