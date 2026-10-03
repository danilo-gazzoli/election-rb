# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Published reports preserve mixed election rounds' do
  include_context 'a mixed majority election'

  it 'publishes both rounds only after resolving the runoff, preserving the first-round winners' do
    finish_mixed_first
    expect { Voting::PublishReport.call(election: election, actor: creator) }
      .to raise_error(Voting::PublishReport::NotReady, /second round/)
    second = prepare_mixed_second
    Voting::OpenRound.call(round: second, actor: creator, now: second.opens_at)
    pair = slates.fetch(contested.id).first(2)
    [pair.first, pair.first, pair.last].each { |candidate| mixed_vote(second, contested.id => candidate) }
    Voting::CloseRound.call(round: second, actor: creator, now: second.grace_until + 1.second)
    report = Voting::PublishReport.call(election: election, actor: creator)
    expect(report.content.fetch('rounds').map { |item| item.fetch('round_number') }).to eq([1, 2])
    expect(report.content.fetch('outcomes')).to match_array([
      { 'contest_id' => decided.id, 'deciding_round' => 1, 'elected_ids' => [slates.fetch(decided.id).first.id] },
      { 'contest_id' => simple.id, 'deciding_round' => 1, 'elected_ids' => [slates.fetch(simple.id).first.id] },
      { 'contest_id' => contested.id, 'deciding_round' => 2, 'elected_ids' => [pair.first.id] }
    ])
    last = report.content.fetch('rounds').last.fetch('contests').first
    expect(last.fetch('totals')).to include('nominal_votes' => 3, 'participation' => 3)
    expect(last.fetch('result')).to include('valid_votes' => 3)
  end
end
