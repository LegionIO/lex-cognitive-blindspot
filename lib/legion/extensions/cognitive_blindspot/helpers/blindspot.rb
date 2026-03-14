# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module CognitiveBlindspot
      module Helpers
        class Blindspot
          include Constants

          attr_reader :id, :domain, :discovered_by, :severity, :description,
                      :status, :created_at, :acknowledged_at, :mitigated_at, :resolved_at

          def initialize(domain:, discovered_by:, description:, severity: DEFAULT_SEVERITY)
            @id             = SecureRandom.uuid
            @domain         = domain.to_sym
            @discovered_by  = discovered_by.to_sym
            @description    = description.to_s
            @severity       = severity.to_f.clamp(0.0, 1.0)
            @status         = :active
            @created_at     = Time.now.utc
            @acknowledged_at = nil
            @mitigated_at   = nil
            @resolved_at    = nil
          end

          def severity_label
            Constants.label_for(SEVERITY_LABELS, @severity) || :negligible
          end

          def active?
            @status == :active
          end

          def acknowledged?
            @status == :acknowledged || @status == :mitigated || @status == :resolved
          end

          def resolved?
            @status == :resolved
          end

          def acknowledge!
            return self if @status != :active

            @status          = :acknowledged
            @acknowledged_at = Time.now.utc
            self
          end

          def mitigate!(boost: SEVERITY_BOOST)
            acknowledge! if @status == :active
            @status        = :mitigated
            @mitigated_at  = Time.now.utc
            @severity      = (@severity - boost).clamp(0.0, 1.0).round(10)
            self
          end

          def resolve!
            acknowledge! if @status == :active
            @status      = :resolved
            @resolved_at = Time.now.utc
            self
          end

          def boost_severity!(amount: SEVERITY_BOOST)
            @severity = (@severity + amount).clamp(0.0, 1.0).round(10)
            self
          end

          def to_h
            {
              id:              @id,
              domain:          @domain,
              discovered_by:   @discovered_by,
              description:     @description,
              severity:        @severity,
              severity_label:  severity_label,
              status:          @status,
              active:          active?,
              acknowledged:    acknowledged?,
              resolved:        resolved?,
              created_at:      @created_at,
              acknowledged_at: @acknowledged_at,
              mitigated_at:    @mitigated_at,
              resolved_at:     @resolved_at
            }
          end
        end
      end
    end
  end
end
