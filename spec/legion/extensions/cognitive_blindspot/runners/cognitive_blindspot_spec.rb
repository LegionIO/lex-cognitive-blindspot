# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveBlindspot::Runners::CognitiveBlindspot do
  subject(:runner) do
    Class.new do
      include Legion::Extensions::CognitiveBlindspot::Runners::CognitiveBlindspot

      def engine
        @engine ||= Legion::Extensions::CognitiveBlindspot::Helpers::BlindspotEngine.new
      end
    end.new
  end

  let(:created) do
    runner.register_blindspot(
      domain:        :reasoning,
      discovered_by: :error_analysis,
      description:   'Over-reliance on recent examples'
    )
  end

  describe '#register_blindspot' do
    it 'returns success: true' do
      expect(created[:success]).to be true
    end

    it 'returns blindspot fields' do
      expect(created).to include(:id, :domain, :severity, :status)
    end

    it 'uses DEFAULT_SEVERITY when severity not provided' do
      expect(created[:severity]).to eq(0.5)
    end

    it 'accepts explicit severity' do
      result = runner.register_blindspot(domain: :x, discovered_by: :unknown,
                                         description: 'test', severity: 0.8)
      expect(result[:severity]).to eq(0.8)
    end
  end

  describe '#acknowledge_blindspot' do
    it 'acknowledges a known blindspot' do
      result = runner.acknowledge_blindspot(blindspot_id: created[:id])
      expect(result[:success]).to be true
      expect(result[:status]).to eq(:acknowledged)
    end

    it 'returns success: false for unknown id' do
      result = runner.acknowledge_blindspot(blindspot_id: 'bad-id')
      expect(result[:success]).to be false
      expect(result[:error]).to eq('blindspot not found')
    end
  end

  describe '#mitigate_blindspot' do
    it 'mitigates a known blindspot' do
      result = runner.mitigate_blindspot(blindspot_id: created[:id])
      expect(result[:success]).to be true
      expect(result[:status]).to eq(:mitigated)
    end

    it 'returns success: false for unknown id' do
      result = runner.mitigate_blindspot(blindspot_id: 'bad-id')
      expect(result[:success]).to be false
    end
  end

  describe '#resolve_blindspot' do
    it 'resolves a known blindspot' do
      result = runner.resolve_blindspot(blindspot_id: created[:id])
      expect(result[:success]).to be true
      expect(result[:status]).to eq(:resolved)
    end

    it 'returns success: false for unknown id' do
      result = runner.resolve_blindspot(blindspot_id: 'bad-id')
      expect(result[:success]).to be false
    end
  end

  describe '#set_knowledge_boundary' do
    it 'returns success: true' do
      result = runner.set_knowledge_boundary(domain: :math, confidence: 0.7, coverage_estimate: 0.5)
      expect(result[:success]).to be true
    end

    it 'returns boundary fields' do
      result = runner.set_knowledge_boundary(domain: :science)
      expect(result).to include(:id, :domain, :confidence, :coverage_estimate)
    end
  end

  describe '#detect_boundary_gap' do
    it 'returns success: true' do
      result = runner.detect_boundary_gap(domain: :math)
      expect(result[:success]).to be true
    end

    it 'detects gap when high confidence + error occurred' do
      runner.set_knowledge_boundary(domain: :math, confidence: 0.8)
      result = runner.detect_boundary_gap(domain: :math, error_occurred: true)
      expect(result[:gap_detected]).to be true
    end
  end

  describe '#active_blindspots_report' do
    it 'returns count and list of active blindspots' do
      created
      result = runner.active_blindspots_report
      expect(result[:success]).to be true
      expect(result[:count]).to eq(1)
      expect(result[:blindspots]).to be_an(Array)
    end
  end

  describe '#most_severe_report' do
    it 'returns list sorted by severity' do
      created
      result = runner.most_severe_report(limit: 3)
      expect(result[:success]).to be true
      expect(result[:limit]).to eq(3)
      expect(result[:blindspots]).to be_an(Array)
    end
  end

  describe '#mitigation_strategies_report' do
    it 'returns strategies' do
      created
      result = runner.mitigation_strategies_report
      expect(result[:success]).to be true
      expect(result[:count]).to eq(1)
    end

    it 'accepts domain filter' do
      created
      result = runner.mitigation_strategies_report(domain: :reasoning)
      expect(result[:success]).to be true
    end
  end

  describe '#coverage_report' do
    it 'returns empty when no boundaries' do
      result = runner.coverage_report
      expect(result[:success]).to be true
      expect(result[:count]).to eq(0)
    end

    it 'returns boundaries after setting one' do
      runner.set_knowledge_boundary(domain: :logic)
      result = runner.coverage_report
      expect(result[:count]).to eq(1)
    end
  end

  describe '#johari_report' do
    it 'returns comprehensive johari window report' do
      created
      report = runner.johari_report
      expect(report).to include(:total_blindspots, :active, :acknowledged,
                                :resolved, :awareness_score, :awareness_label)
    end
  end

  describe '#awareness_score_report' do
    it 'returns awareness metrics' do
      result = runner.awareness_score_report
      expect(result[:success]).to be true
      expect(result).to include(:awareness_score, :awareness_label, :awareness_gap)
    end
  end

  describe '#blindspot_stats' do
    it 'returns summary stats hash' do
      result = runner.blindspot_stats
      expect(result).to include(:total_blindspots, :awareness_score)
    end
  end
end
