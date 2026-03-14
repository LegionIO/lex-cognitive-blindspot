# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveBlindspot::Helpers::Blindspot do
  subject(:blindspot) do
    described_class.new(
      domain:        :epistemology,
      discovered_by: :error_analysis,
      description:   'Failed to account for selection bias in training data',
      severity:      0.6
    )
  end

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(blindspot.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores domain as symbol' do
      expect(blindspot.domain).to eq(:epistemology)
    end

    it 'stores discovered_by as symbol' do
      expect(blindspot.discovered_by).to eq(:error_analysis)
    end

    it 'stores description' do
      expect(blindspot.description).to eq('Failed to account for selection bias in training data')
    end

    it 'clamps severity to 0..1' do
      spot = described_class.new(domain: :test, discovered_by: :unknown, description: 'x', severity: 2.0)
      expect(spot.severity).to eq(1.0)
    end

    it 'starts with status :active' do
      expect(blindspot.status).to eq(:active)
    end

    it 'starts with created_at set' do
      expect(blindspot.created_at).to be_a(Time)
    end
  end

  describe '#severity_label' do
    it 'returns :high for severity 0.6' do
      expect(blindspot.severity_label).to eq(:high)
    end

    it 'returns :critical for severity 0.9' do
      spot = described_class.new(domain: :x, discovered_by: :unknown, description: 'x', severity: 0.9)
      expect(spot.severity_label).to eq(:critical)
    end

    it 'returns :negligible for severity 0.1' do
      spot = described_class.new(domain: :x, discovered_by: :unknown, description: 'x', severity: 0.1)
      expect(spot.severity_label).to eq(:negligible)
    end
  end

  describe '#active?' do
    it 'returns true when status is :active' do
      expect(blindspot.active?).to be true
    end

    it 'returns false after acknowledging' do
      blindspot.acknowledge!
      expect(blindspot.active?).to be false
    end
  end

  describe '#acknowledged?' do
    it 'returns false initially' do
      expect(blindspot.acknowledged?).to be false
    end

    it 'returns true after acknowledging' do
      blindspot.acknowledge!
      expect(blindspot.acknowledged?).to be true
    end

    it 'returns true after mitigating' do
      blindspot.mitigate!
      expect(blindspot.acknowledged?).to be true
    end

    it 'returns true after resolving' do
      blindspot.resolve!
      expect(blindspot.acknowledged?).to be true
    end
  end

  describe '#resolved?' do
    it 'returns false initially' do
      expect(blindspot.resolved?).to be false
    end

    it 'returns true after resolving' do
      blindspot.resolve!
      expect(blindspot.resolved?).to be true
    end
  end

  describe '#acknowledge!' do
    it 'sets status to :acknowledged' do
      blindspot.acknowledge!
      expect(blindspot.status).to eq(:acknowledged)
    end

    it 'sets acknowledged_at' do
      blindspot.acknowledge!
      expect(blindspot.acknowledged_at).not_to be_nil
    end

    it 'is idempotent — does not re-set acknowledged_at on second call' do
      blindspot.acknowledge!
      first_time = blindspot.acknowledged_at
      blindspot.acknowledge!
      expect(blindspot.acknowledged_at).to eq(first_time)
    end

    it 'returns self' do
      expect(blindspot.acknowledge!).to eq(blindspot)
    end
  end

  describe '#mitigate!' do
    it 'sets status to :mitigated' do
      blindspot.mitigate!
      expect(blindspot.status).to eq(:mitigated)
    end

    it 'reduces severity by SEVERITY_BOOST' do
      before = blindspot.severity
      blindspot.mitigate!
      expect(blindspot.severity).to be < before
    end

    it 'sets mitigated_at' do
      blindspot.mitigate!
      expect(blindspot.mitigated_at).not_to be_nil
    end

    it 'auto-acknowledges an active blindspot' do
      blindspot.mitigate!
      expect(blindspot.acknowledged_at).not_to be_nil
    end

    it 'returns self' do
      expect(blindspot.mitigate!).to eq(blindspot)
    end
  end

  describe '#resolve!' do
    it 'sets status to :resolved' do
      blindspot.resolve!
      expect(blindspot.status).to eq(:resolved)
    end

    it 'sets resolved_at' do
      blindspot.resolve!
      expect(blindspot.resolved_at).not_to be_nil
    end

    it 'returns self' do
      expect(blindspot.resolve!).to eq(blindspot)
    end
  end

  describe '#boost_severity!' do
    it 'increases severity' do
      before = blindspot.severity
      blindspot.boost_severity!
      expect(blindspot.severity).to be > before
    end

    it 'clamps to 1.0' do
      spot = described_class.new(domain: :x, discovered_by: :unknown, description: 'x', severity: 0.95)
      spot.boost_severity!(amount: 0.2)
      expect(spot.severity).to eq(1.0)
    end

    it 'returns self' do
      expect(blindspot.boost_severity!).to eq(blindspot)
    end
  end

  describe '#to_h' do
    it 'returns a hash with all required keys' do
      h = blindspot.to_h
      expect(h).to include(:id, :domain, :discovered_by, :description,
                           :severity, :severity_label, :status,
                           :active, :acknowledged, :resolved, :created_at)
    end

    it 'includes nil acknowledged_at initially' do
      expect(blindspot.to_h[:acknowledged_at]).to be_nil
    end

    it 'includes acknowledged_at after acknowledging' do
      blindspot.acknowledge!
      expect(blindspot.to_h[:acknowledged_at]).not_to be_nil
    end
  end
end
