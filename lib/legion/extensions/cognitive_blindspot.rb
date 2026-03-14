# frozen_string_literal: true

require_relative 'cognitive_blindspot/version'
require_relative 'cognitive_blindspot/helpers/constants'
require_relative 'cognitive_blindspot/helpers/blindspot'
require_relative 'cognitive_blindspot/helpers/knowledge_boundary'
require_relative 'cognitive_blindspot/helpers/blindspot_engine'
require_relative 'cognitive_blindspot/runners/cognitive_blindspot'
require_relative 'cognitive_blindspot/client'

module Legion
  module Extensions
    module CognitiveBlindspot
      extend Legion::Extensions::Core if defined?(Legion::Extensions::Core)
    end
  end
end
