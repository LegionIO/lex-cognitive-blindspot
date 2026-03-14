# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveBlindspot::Helpers::BlindspotEngine do
  subject(:engine) { described_class.new }

  let(:blindspot) do
    engine.register_blindspot(
      domain:        :reasoning,
      discovered_by: :error_analysis,
      description:   'Confirmation bias in evidence weighing'
    )
  end

  describe '#initialize' do
    it 'starts with awareness_score of 1.0' do
      expect(engine.awareness_score).to eq(1.0)
    end
  end

  describe '#register_blindspot' do
    it 'returns a Blindspot object' do
      expect(blindspot).to be_a(Legion::Extensions::CognitiveBlindspot::Helpers::Blindspot)
    end

    it 'assigns a uuid' do
      expect(blindspot.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'recalculates awareness score after registration' do
      blindspot
      expect(engine.awareness_score).to be < 1.0
    end
  end

  describe '#acknowledge_blindspot' do
    it 'returns found: false for unknown id' do
      result = engine.acknowledge_blindspot(blindspot_id: 'bad-id')
      expect(result[:found]).to be false
    end

    it 'acknowledges a known blindspot' do
      result = engine.acknowledge_blindspot(blindspot_id: blindspot.id)
      expect(result[:found]).to be true
      expect(result[:status]).to eq(:acknowledged)
    end

    it 'updates awareness score after acknowledging' do
      engine.acknowledge_blindspot(blindspot_id: blindspot.id)
      expect(engine.awareness_score).to eq(1.0)
    end
  end

  describe '#mitigate_blindspot' do
    it 'returns found: false for unknown id' do
      result = engine.mitigate_blindspot(blindspot_id: 'bad-id')
      expect(result[:found]).to be false
    end

    it 'mitigates a known blindspot' do
      result = engine.mitigate_blindspot(blindspot_id: blindspot.id)
      expect(result[:found]).to be true
      expect(result[:status]).to eq(:mitigated)
    end

    it 'reduces severity on mitigation' do
      before = blindspot.severity
      engine.mitigate_blindspot(blindspot_id: blindspot.id)
      expect(blindspot.severity).to be < before
    end
  end

  describe '#resolve_blindspot' do
    it 'returns found: false for unknown id' do
      result = engine.resolve_blindspot(blindspot_id: 'bad-id')
      expect(result[:found]).to be false
    end

    it 'resolves a known blindspot' do
      result = engine.resolve_blindspot(blindspot_id: blindspot.id)
      expect(result[:found]).to be true
      expect(result[:status]).to eq(:resolved)
    end
  end

  describe '#set_boundary' do
    it 'creates a new boundary' do
      b = engine.set_boundary(domain: :math, confidence: 0.8, coverage_estimate: 0.6)
      expect(b).to be_a(Legion::Extensions::CognitiveBlindspot::Helpers::KnowledgeBoundary)
    end

    it 'updates existing boundary for same domain' do
      engine.set_boundary(domain: :math, confidence: 0.5)
      b2 = engine.set_boundary(domain: :math, confidence: 0.9)
      expect(b2.confidence).to eq(0.9)
    end
  end

  describe '#detect_boundary_gap' do
    it 'returns gap_detected: false when no boundary set' do
      result = engine.detect_boundary_gap(domain: :unknown_domain, error_occurred: true)
      expect(result[:gap_detected]).to be false
      expect(result[:reason]).to eq(:no_boundary)
    end

    it 'returns gap_detected: true when error occurs and confidence is high' do
      engine.set_boundary(domain: :physics, confidence: 0.8)
      result = engine.detect_boundary_gap(domain: :physics, error_occurred: true)
      expect(result[:gap_detected]).to be true
    end

    it 'returns gap_detected: false when no error' do
      engine.set_boundary(domain: :physics, confidence: 0.8)
      result = engine.detect_boundary_gap(domain: :physics, error_occurred: false)
      expect(result[:gap_detected]).to be false
    end
  end

  describe '#blindspots_by_domain' do
    it 'returns blindspots matching domain' do
      blindspot
      results = engine.blindspots_by_domain(:reasoning)
      expect(results.size).to eq(1)
      expect(results.first.domain).to eq(:reasoning)
    end

    it 'returns empty for non-existent domain' do
      expect(engine.blindspots_by_domain(:unknown_xyz)).to be_empty
    end
  end

  describe '#active_blindspots' do
    it 'returns only active blindspots' do
      blindspot
      expect(engine.active_blindspots.size).to eq(1)
    end

    it 'excludes acknowledged blindspots' do
      engine.acknowledge_blindspot(blindspot_id: blindspot.id)
      expect(engine.active_blindspots).to be_empty
    end
  end

  describe '#acknowledged_blindspots' do
    it 'returns acknowledged blindspots' do
      engine.acknowledge_blindspot(blindspot_id: blindspot.id)
      expect(engine.acknowledged_blindspots.size).to eq(1)
    end
  end

  describe '#resolved_blindspots' do
    it 'returns resolved blindspots' do
      engine.resolve_blindspot(blindspot_id: blindspot.id)
      expect(engine.resolved_blindspots.size).to eq(1)
    end
  end

  describe '#most_severe' do
    it 'returns blindspots sorted by severity descending' do
      engine.register_blindspot(domain: :a, discovered_by: :unknown,
                                description: 'low', severity: 0.2)
      high = engine.register_blindspot(domain: :b, discovered_by: :unknown,
                                       description: 'high', severity: 0.9)
      result = engine.most_severe(limit: 2)
      expect(result.first.id).to eq(high.id)
    end

    it 'respects limit' do
      3.times { |i| engine.register_blindspot(domain: :x, discovered_by: :unknown, description: "s#{i}") }
      expect(engine.most_severe(limit: 2).size).to eq(2)
    end
  end

  describe '#mitigation_strategies' do
    it 'returns strategies for active blindspots' do
      blindspot
      strategies = engine.mitigation_strategies
      expect(strategies.size).to eq(1)
      expect(strategies.first).to include(:blindspot_id, :domain, :severity, :strategy)
    end

    it 'returns strategies filtered by domain' do
      blindspot
      engine.register_blindspot(domain: :other, discovered_by: :unknown, description: 'other')
      strategies = engine.mitigation_strategies(domain: :reasoning)
      expect(strategies.size).to eq(1)
    end

    it 'returns empty after all are acknowledged' do
      engine.acknowledge_blindspot(blindspot_id: blindspot.id)
      expect(engine.mitigation_strategies).to be_empty
    end
  end

  describe '#coverage_report' do
    it 'returns empty when no boundaries set' do
      expect(engine.coverage_report).to be_empty
    end

    it 'returns boundaries as hashes' do
      engine.set_boundary(domain: :logic, confidence: 0.7)
      report = engine.coverage_report
      expect(report.size).to eq(1)
      expect(report.first).to include(:domain, :confidence, :coverage_estimate)
    end
  end

  describe '#awareness_label' do
    it 'returns :unaware when score is 0' do
      engine.register_blindspot(domain: :x, discovered_by: :unknown, description: 'x')
      expect(engine.awareness_label).to be_a(Symbol)
    end

    it 'returns :highly_aware at score 1.0' do
      expect(engine.awareness_label).to eq(:highly_aware)
    end
  end

  describe '#awareness_gap' do
    it 'returns 0.0 when no blindspots' do
      expect(engine.awareness_gap).to eq(0.0)
    end

    it 'is complement of awareness_score' do
      blindspot
      expect((engine.awareness_score + engine.awareness_gap).round(10)).to eq(1.0)
    end
  end

  describe '#johari_report' do
    it 'returns comprehensive report' do
      blindspot
      report = engine.johari_report
      expect(report).to include(:total_blindspots, :active, :acknowledged, :resolved,
                                :awareness_score, :awareness_label, :awareness_gap,
                                :boundaries_tracked, :most_severe)
    end
  end

  describe '#to_h' do
    it 'returns summary stats' do
      h = engine.to_h
      expect(h).to include(:total_blindspots, :active, :acknowledged,
                           :resolved, :awareness_score, :awareness_label)
    end
  end
end
