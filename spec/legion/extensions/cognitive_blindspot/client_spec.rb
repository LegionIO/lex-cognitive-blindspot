# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveBlindspot::Client do
  subject(:client) { described_class.new }

  it 'includes the runner module' do
    expect(client).to respond_to(:register_blindspot)
  end

  it 'provides a BlindspotEngine' do
    expect(client.engine).to be_a(
      Legion::Extensions::CognitiveBlindspot::Helpers::BlindspotEngine
    )
  end

  it 'registers and acknowledges a blindspot' do
    result = client.register_blindspot(
      domain:        :logic,
      discovered_by: :self_reflection,
      description:   'Underestimates rare events'
    )
    expect(result[:success]).to be true

    ack = client.acknowledge_blindspot(blindspot_id: result[:id])
    expect(ack[:success]).to be true
    expect(ack[:status]).to eq(:acknowledged)
  end

  it 'full lifecycle: register -> mitigate -> resolve' do
    reg = client.register_blindspot(domain: :planning, discovered_by: :peer_feedback,
                                    description: 'Overestimates available time')
    client.mitigate_blindspot(blindspot_id: reg[:id])
    res = client.resolve_blindspot(blindspot_id: reg[:id])
    expect(res[:status]).to eq(:resolved)
  end

  it 'awareness score is 1.0 with no blindspots' do
    report = client.awareness_score_report
    expect(report[:awareness_score]).to eq(1.0)
  end
end
