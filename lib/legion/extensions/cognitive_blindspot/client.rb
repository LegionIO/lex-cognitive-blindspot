# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveBlindspot
      class Client
        include Runners::CognitiveBlindspot

        def engine
          @engine ||= Helpers::BlindspotEngine.new
        end
      end
    end
  end
end
