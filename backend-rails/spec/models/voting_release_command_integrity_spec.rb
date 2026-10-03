# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Voting release command database integrity' do
  include_context 'an opened school voting round'

  let(:attributes) do
    { voting_device_id: device.id, round_id: round.id, voting_session_id: voting_session.id,
      command_key: 'durable-release-command' }
  end
  let(:command) { VotingReleaseCommand.create!(attributes) }

  def insert(changes = {})
    VotingReleaseCommand.insert_all!([attributes.merge(changes)])
  end

  it 'stores the original device, round and session identity without vote or credential fields' do
    expect(command.reload).to have_attributes(attributes)
    expect(command.attributes.keys).not_to include('candidacy_id', 'party_id', 'vote_id',
                                                  'credential_digest', 'first_choice_fingerprint')
  end

  it 'rejects a duplicate key for the same device through direct insertion' do
    command
    expect { insert }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it 'allows independent devices to use the same command key without sharing a session' do
    command
    other_device = VotingDevice.create!(school_installation: school, public_label: 'Second device',
                                        credential_digest: 'second-digest', state: 'locked')
    other_session = Voting::Release.call(round: round, device: other_device, actor: pollworker, now: now)
    expect do
      insert(voting_device_id: other_device.id, voting_session_id: other_session.id)
    end.to change(VotingReleaseCommand, :count).by(1)
  end

  it 'rejects a command bound to a session belonging to another device' do
    other_device = VotingDevice.create!(school_installation: school, public_label: 'Wrong device',
                                        credential_digest: 'wrong-digest', state: 'locked')
    expect { insert(voting_device_id: other_device.id) }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it 'rejects a command bound to a session belonging to another round' do
    other_round = Round.create!(election: election, number: 2, state: 'draft', opens_at: round.opens_at,
                                closes_at: round.closes_at, grace_until: round.grace_until)
    expect { insert(round_id: other_round.id) }.to raise_error(ActiveRecord::StatementInvalid)
  end

  [nil, '', '   '].each do |key|
    it "rejects the invalid key #{key.inspect} through direct insertion" do
      expect { insert(command_key: key) }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end

  it 'rejects a key longer than the documented 128-character boundary through direct insertion' do
    expect { insert(command_key: 'x' * 129) }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it 'rejects rewriting the durable command key through direct SQL' do
    expect { command.update_columns(command_key: 'replacement-key') }
      .to raise_error(ActiveRecord::StatementInvalid)
  end

  it 'rejects deletion of the durable release command through direct SQL' do
    command
    expect { VotingReleaseCommand.where(id: command.id).delete_all }
      .to raise_error(ActiveRecord::StatementInvalid)
  end
end
