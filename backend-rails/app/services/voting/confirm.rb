# frozen_string_literal: true

module Voting
  class Confirm
    class Conflict < StandardError; end
    class NotAllowed < StandardError; end

    Result = Data.define(:status, :receipt_id, :next_stage_position)

    def self.call(**arguments)
      new(**arguments).call
    end

    def initialize(session:, stage_id:, command_key:, kind:, candidacy_id: nil, party_id: nil,
                   warning_acknowledged: false, secret: Rails.application.secret_key_base, now: Time.current)
      @session = session
      @stage_id = stage_id
      @command_key = command_key
      @kind = kind
      @candidacy_id = candidacy_id
      @party_id = party_id
      @warning_acknowledged = warning_acknowledged
      @secret = secret
      @now = now
    end

    def call
      committed = false
      result = @session.with_lock do
        existing = @session.confirmation_receipts.find_by(voting_stage_id: @stage_id)
        next confirmed(existing) if existing

        validate_command!
        stage = VotingStage.find_by(id: @stage_id, round_id: @session.round_id,
                                    global_position: @session.current_stage_position)
        raise Conflict, 'unexpected voting stage' unless stage

        contest = stage.round_contest.contest
        choice = classify_choice(contest)
        if choice == :warning
          next Result.new(status: :warning_required, receipt_id: nil,
                          next_stage_position: @session.current_stage_position)
        end

        CastVote.create!(round: @session.round, contest: contest, voting_stage: stage,
                         kind: choice, origin: 'confirmation',
                         candidacy_id: choice == 'nominal' ? @candidacy_id : nil,
                         party_id: choice == 'legend' ? @party_id : nil)
        receipt = ConfirmationReceipt.create!(voting_session: @session, voting_stage: stage,
                                              command_key: @command_key, confirmed_at: @now)
        advance!(stage, contest, choice)
        committed = true
        confirmed(receipt)
      end
      NotifyDeviceState.call(device_id: @session.voting_device_id) if committed
      result
    end

    private

    def confirmed(receipt)
      Result.new(status: :confirmed, receipt_id: receipt.id,
                 next_stage_position: @session.current_stage_position)
    end

    def validate_command!
      raise Conflict, 'command key is required' unless @command_key.is_a?(String) && @command_key.present?
      raise Conflict, 'command key already used' if @session.confirmation_receipts.exists?(command_key: @command_key)
      raise NotAllowed, 'session is not active' unless %w[released in_progress].include?(@session.state)
      raise NotAllowed, 'round is not open' unless @session.round.state == 'open'
      raise NotAllowed, 'outside voting window' unless @now >= @session.round.opens_at &&
                                                         @now <= @session.round.grace_until
      raise NotAllowed, 'new session cannot start after closing' if @session.started_at.nil? &&
                                                                 @now >= @session.round.closes_at
    end

    def classify_choice(contest)
      case @kind
      when 'nominal'
        candidate = Candidacy.find_by(id: @candidacy_id, contest_id: contest.id, state: 'active')
        raise NotAllowed, 'candidacy is not eligible' unless candidate &&
                                                       RoundCandidacy.exists?(round_id: @session.round_id,
                                                                              candidacy_id: candidate.id,
                                                                              eligible: true)
        return 'nominal' unless contest.two_choice_majoritarian? &&
                                @session.current_stage_position == second_position(contest)

        decision = second_choice_rule(contest).decide(first_choice_fingerprint: @session.first_choice_fingerprint,
                                                      candidate_id: candidate.id,
                                                      warning_acknowledged: @warning_acknowledged)
        return :warning if decision.warning_required?

        decision.vote_type == :null ? 'null' : 'nominal'
      when 'legend'
        raise NotAllowed, 'legend requires a proportional contest' unless contest.method == 'proportional'
        raise NotAllowed, 'party is not eligible' unless ElectionPartyRegistration.exists?(
          election_id: contest.election_id, party_id: @party_id
        )

        'legend'
      when 'blank', 'null'
        raise NotAllowed, 'option identifier is not allowed' if @candidacy_id || @party_id

        @kind
      else
        raise NotAllowed, 'unsupported vote kind'
      end
    end

    def second_position(contest)
      VotingStage.joins(:round_contest)
                 .find_by(round_id: @session.round_id, round_contests: { contest_id: contest.id },
                          choice_index: 2)&.global_position
    end

    def second_choice_rule(contest)
      MajoritarianSecondChoice.new(secret: @secret, session_token: @session.id,
                                   contest_token: contest.id.to_s)
    end

    def advance!(stage, contest, choice)
      if contest.two_choice_majoritarian?
        @session.first_choice_fingerprint = stage.choice_index == 1 && choice == 'nominal' ?
          second_choice_rule(contest).fingerprint_for(@candidacy_id) : nil
      end
      @session.started_at ||= @now
      @session.current_stage_position += 1
      next_stage = VotingStage.exists?(round_id: @session.round_id,
                                       global_position: @session.current_stage_position)
      @session.state = next_stage ? 'in_progress' : 'completed'
      @session.ended_at = @now unless next_stage
      @session.save!
      @session.voting_device.update!(state: next_stage ? 'in_progress' : 'locked')
    end
  end
end
