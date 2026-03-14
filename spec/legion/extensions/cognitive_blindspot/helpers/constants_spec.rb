# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveBlindspot::Helpers::Constants do
  it 'defines MAX_BLINDSPOTS' do
    expect(described_class::MAX_BLINDSPOTS).to eq(300)
  end

  it 'defines MAX_BOUNDARIES' do
    expect(described_class::MAX_BOUNDARIES).to eq(50)
  end

  it 'defines DEFAULT_SEVERITY' do
    expect(described_class::DEFAULT_SEVERITY).to eq(0.5)
  end

  it 'defines SEVERITY_BOOST' do
    expect(described_class::SEVERITY_BOOST).to eq(0.1)
  end

  it 'defines AWARENESS_THRESHOLD' do
    expect(described_class::AWARENESS_THRESHOLD).to eq(0.6)
  end

  it 'defines DISCOVERY_METHODS as a frozen array with 8 entries' do
    expect(described_class::DISCOVERY_METHODS).to be_frozen
    expect(described_class::DISCOVERY_METHODS.size).to eq(8)
    expect(described_class::DISCOVERY_METHODS).to include(:error_analysis, :peer_feedback, :unknown)
  end

  it 'defines SEVERITY_LABELS for full range' do
    expect(described_class::SEVERITY_LABELS.size).to eq(5)
  end

  it 'defines AWARENESS_LABELS for full range' do
    expect(described_class::AWARENESS_LABELS.size).to eq(5)
  end

  it 'defines COVERAGE_LABELS for full range' do
    expect(described_class::COVERAGE_LABELS.size).to eq(5)
  end

  it 'defines STATUS_LABELS for all statuses' do
    expect(described_class::STATUS_LABELS).to include(:active, :acknowledged, :mitigated, :resolved)
  end

  describe '.label_for' do
    it 'returns the correct label for a value in range' do
      label = described_class.label_for(described_class::SEVERITY_LABELS, 0.9)
      expect(label).to eq(:critical)
    end

    it 'returns :high for 0.7' do
      label = described_class.label_for(described_class::SEVERITY_LABELS, 0.7)
      expect(label).to eq(:high)
    end

    it 'returns :moderate for 0.5' do
      label = described_class.label_for(described_class::SEVERITY_LABELS, 0.5)
      expect(label).to eq(:moderate)
    end

    it 'returns :negligible for 0.1' do
      label = described_class.label_for(described_class::SEVERITY_LABELS, 0.1)
      expect(label).to eq(:negligible)
    end

    it 'returns nil for a value with no matching range' do
      label = described_class.label_for({}, 0.5)
      expect(label).to be_nil
    end

    it 'returns correct awareness label' do
      label = described_class.label_for(described_class::AWARENESS_LABELS, 0.85)
      expect(label).to eq(:highly_aware)
    end

    it 'returns correct coverage label' do
      label = described_class.label_for(described_class::COVERAGE_LABELS, 0.3)
      expect(label).to eq(:limited)
    end
  end
end
