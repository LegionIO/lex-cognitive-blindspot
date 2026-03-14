# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveBlindspot::Helpers::KnowledgeBoundary do
  subject(:boundary) do
    described_class.new(domain: :physics, confidence: 0.7, coverage_estimate: 0.5)
  end

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(boundary.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores domain as symbol' do
      expect(boundary.domain).to eq(:physics)
    end

    it 'clamps confidence to 0..1' do
      b = described_class.new(domain: :x, confidence: 1.5)
      expect(b.confidence).to eq(1.0)
    end

    it 'clamps coverage_estimate to 0..1' do
      b = described_class.new(domain: :x, coverage_estimate: -0.5)
      expect(b.coverage_estimate).to eq(0.0)
    end

    it 'sets created_at' do
      expect(boundary.created_at).to be_a(Time)
    end
  end

  describe '#coverage_label' do
    it 'returns :partial for coverage 0.5' do
      expect(boundary.coverage_label).to eq(:partial)
    end

    it 'returns :comprehensive for coverage 0.9' do
      b = described_class.new(domain: :x, coverage_estimate: 0.9)
      expect(b.coverage_label).to eq(:comprehensive)
    end

    it 'returns :minimal for coverage 0.1' do
      b = described_class.new(domain: :x, coverage_estimate: 0.1)
      expect(b.coverage_label).to eq(:minimal)
    end
  end

  describe '#gap_detected?' do
    it 'returns false when no error occurred' do
      expect(boundary.gap_detected?(error_occurred: false)).to be false
    end

    it 'returns true when error occurred and confidence is above threshold' do
      expect(boundary.gap_detected?(error_occurred: true)).to be true
    end

    it 'returns false when error occurred but confidence is below threshold' do
      b = described_class.new(domain: :x, confidence: 0.4)
      expect(b.gap_detected?(error_occurred: true)).to be false
    end
  end

  describe '#update_confidence!' do
    it 'updates confidence value' do
      boundary.update_confidence!(0.3)
      expect(boundary.confidence).to eq(0.3)
    end

    it 'updates updated_at' do
      original = boundary.updated_at
      sleep(0.001)
      boundary.update_confidence!(0.9)
      expect(boundary.updated_at).to be >= original
    end

    it 'returns self' do
      expect(boundary.update_confidence!(0.5)).to eq(boundary)
    end
  end

  describe '#update_coverage!' do
    it 'updates coverage_estimate' do
      boundary.update_coverage!(0.8)
      expect(boundary.coverage_estimate).to eq(0.8)
    end

    it 'returns self' do
      expect(boundary.update_coverage!(0.5)).to eq(boundary)
    end
  end

  describe '#to_h' do
    it 'returns a hash with all required keys' do
      h = boundary.to_h
      expect(h).to include(:id, :domain, :confidence, :coverage_estimate,
                           :coverage_label, :created_at, :updated_at)
    end

    it 'reflects current confidence' do
      boundary.update_confidence!(0.2)
      expect(boundary.to_h[:confidence]).to eq(0.2)
    end
  end
end
