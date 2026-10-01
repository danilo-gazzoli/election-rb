# frozen_string_literal: true

class ContestProfile
  def initialize(method:, seats:, choices_per_person:, has_vice:)
    @method = method
    @seats = seats
    @choices_per_person = choices_per_person
    @has_vice = has_vice
  end

  def valid?
    case @method
    when 'proportional'
      @seats.is_a?(Integer) && @seats.positive? && @choices_per_person == 1 && @has_vice == false
    when 'absolute_majority'
      @seats == 1 && @choices_per_person == 1 && [true, false].include?(@has_vice)
    when 'simple_majority'
      (@seats == 1 && @choices_per_person == 1 || @seats == 2 && @choices_per_person == 2) &&
        [true, false].include?(@has_vice)
    else
      false
    end
  end
end
