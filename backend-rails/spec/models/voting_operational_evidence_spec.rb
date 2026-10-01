# frozen_string_literal: true

require 'rails_helper'

# ERS RF-39/RF-42: reconciliation evidence must survive direct SQL changes.
RSpec.describe 'Voting operational evidence integrity' do
  include_context 'an opened school voting round'

  let(:closure) do
    confirm_first_vote
    Voting::Abandon.call(session: voting_session, actor: pollworker, reason: 'Voter left', now: now)
    Incident.find_by!(voting_session: voting_session, kind: 'abandoned')
  end

  def closure_attributes
    { round_id: round.id, voting_session_id: voting_session.id, user_id: pollworker.id,
      kind: 'abandoned', reason: 'Voter left', occurred_at: now,
      remaining_stage_ids: [second_stage.id] }
  end

  # Savepoints isolate rejected SQL so later assertions can still query PostgreSQL.
  def expect_rejected_sql(&operation)
    expect do
      ActiveRecord::Base.transaction(requires_new: true, &operation)
    end.to raise_error(ActiveRecord::StatementInvalid)
  end

  it 'prevents changing an incident even through direct SQL' do
    original = closure.attributes
    expect_rejected_sql { Incident.where(id: closure.id).update_all(reason: 'Rewritten') }
    expect(closure.reload.attributes).to eq(original)
  end

  it 'prevents deleting the evidence for an administrative null' do
    closure
    expect_rejected_sql { Incident.where(id: closure.id).delete_all }
    expect(Incident.where(id: closure.id)).to exist
  end

  it 'prevents changing the actor or reason of an audit event' do
    event = AuditEvent.find_by!(action: 'round_open')
    original = event.attributes
    expect_rejected_sql { AuditEvent.where(id: event.id).update_all(user_id: pollworker.id, reason: 'Rewritten') }
    expect(event.reload.attributes).to eq(original)
  end

  it 'prevents deleting an audit event' do
    event = AuditEvent.find_by!(action: 'round_open')
    expect_rejected_sql { AuditEvent.where(id: event.id).delete_all }
    expect(AuditEvent.where(id: event.id)).to exist
  end

  it 'allows only one formal closure evidence per session across closure kinds' do
    closure
    attributes = closure_attributes.merge(kind: 'cancelled', remaining_stage_ids: [])
    expect_rejected_sql { Incident.insert_all!([attributes]) }
    expect(Incident.where(voting_session: voting_session).count).to eq(1)
  end

  it 'requires an operator for new closure evidence' do
    expect_rejected_sql { Incident.insert_all!([closure_attributes.merge(user_id: nil)]) }
  end

  it 'requires a session for new closure evidence' do
    expect_rejected_sql { Incident.insert_all!([closure_attributes.merge(voting_session_id: nil)]) }
  end

  [nil, {}, ['not-a-stage'], [1.5], [0], [-1]].each do |evidence|
    it "rejects invalid stage evidence #{evidence.inspect} at database insertion" do
      expect_rejected_sql { Incident.insert_all!([closure_attributes.merge(remaining_stage_ids: evidence)]) }
    end
  end

  it 'rejects duplicated stages in the same evidence' do
    expect_rejected_sql do
      Incident.insert_all!([closure_attributes.merge(remaining_stage_ids: [second_stage.id, second_stage.id])])
    end
  end

  it 'rejects nonempty evidence for an unstarted cancellation' do
    expect_rejected_sql { Incident.insert_all!([closure_attributes.merge(kind: 'cancelled')]) }
  end

  it 'rejects closure evidence referring to a session in another round' do
    another_round = Round.create!(election: election, number: 2, state: 'draft',
                                  opens_at: now + 2.hours, closes_at: now + 3.hours,
                                  grace_until: now + 190.minutes)
    expect_rejected_sql { Incident.insert_all!([closure_attributes.merge(round_id: another_round.id)]) }
  end

  it 'rejects stage identifiers that do not belong to the incident round' do
    expect_rejected_sql do
      Incident.insert_all!([closure_attributes.merge(remaining_stage_ids: [VotingStage.maximum(:id) + 1])])
    end
  end

  it 'rejects an operator from a different school' do
    other_school = SchoolInstallation.create!(identifier: 'other-evidence-school', name: 'Other School')
    foreign_operator = user('foreign-operator', other_school)
    expect_rejected_sql { Incident.insert_all!([closure_attributes.merge(user_id: foreign_operator.id)]) }
  end
end
