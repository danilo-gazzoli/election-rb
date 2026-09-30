# frozen_string_literal: true

class VotingStagePlan
  def self.call(contests)
    positions = contests.map { |contest| contest.fetch(:position) }
    raise ArgumentError, 'contest positions must be consecutive and unique' unless positions.sort == (1..contests.size).to_a

    contests.sort_by { |contest| contest.fetch(:position) }.flat_map do |contest|
      choices = contest.fetch(:choices_per_person)
      raise ArgumentError, 'invalid choices per person' unless choices.is_a?(Integer) && choices.positive?

      (1..choices).map { |choice_index| { contest_id: contest.fetch(:id), choice_index: choice_index } }
    end.each_with_index.map do |stage, index|
      stage.merge(global_position: index + 1)
    end
  end
end
