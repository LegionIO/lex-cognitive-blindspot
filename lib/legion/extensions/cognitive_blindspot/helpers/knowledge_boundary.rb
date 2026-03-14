# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module CognitiveBlindspot
      module Helpers
        class KnowledgeBoundary
          include Constants

          attr_reader :id, :domain, :confidence, :coverage_estimate, :created_at, :updated_at

          def initialize(domain:, confidence: 0.5, coverage_estimate: 0.5)
            @id               = SecureRandom.uuid
            @domain           = domain.to_sym
            @confidence       = confidence.to_f.clamp(0.0, 1.0)
            @coverage_estimate = coverage_estimate.to_f.clamp(0.0, 1.0)
            @created_at       = Time.now.utc
            @updated_at       = Time.now.utc
          end

          def coverage_label
            Constants.label_for(COVERAGE_LABELS, @coverage_estimate) || :minimal
          end

          def gap_detected?(error_occurred: false)
            error_occurred && @confidence >= AWARENESS_THRESHOLD
          end

          def update_confidence!(new_confidence)
            @confidence  = new_confidence.to_f.clamp(0.0, 1.0)
            @updated_at  = Time.now.utc
            self
          end

          def update_coverage!(new_coverage)
            @coverage_estimate = new_coverage.to_f.clamp(0.0, 1.0)
            @updated_at        = Time.now.utc
            self
          end

          def to_h
            {
              id:                @id,
              domain:            @domain,
              confidence:        @confidence,
              coverage_estimate: @coverage_estimate,
              coverage_label:    coverage_label,
              created_at:        @created_at,
              updated_at:        @updated_at
            }
          end
        end
      end
    end
  end
end
