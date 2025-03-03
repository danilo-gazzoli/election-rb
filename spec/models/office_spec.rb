# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Office', type: :model do
  let(:office) { build(:office) }

  describe 'name validations' do
    context 'positive validations' do
      it 'is valid when name present' do
        office.name = 'president'
        expect(office).to be_valid
      end

      it 'is valid when name length is grater than 5 characters' do
        office.name = 'president'
        expect(office).to be_valid
      end
    end

    context 'negative validations' do
      it 'is not valid when name is nil' do
        office.name = nil
        expect(office).to_not be_valid
      end

      it 'is not valid when name length is less than 5 characters' do
        office.name = 'abc'
        expect(office).to_not be_valid
      end
    end
  end

  describe 'num_of_seats validations' do
    context 'positive validations' do
      it 'is valid when num_of_seats is present' do
        office.num_of_seats = 2
        expect(office).to be_valid
      end

      it 'is valid when num_of_seats is a integer number' do
        office.num_of_seats = 2
        expect(office).to be_valid
      end

      it 'is valid when num_of_seats is grater than or equal 1' do
        office.num_of_seats = 1
        expect(office).to be_valid
      end
    end

    context 'negative validations' do
      it 'is not valid when num_of_seats is nil' do
        office.num_of_seats = nil
        expect(office).to_not be_valid
      end

      it 'is not valid when num_of_seats is not a integer number' do
        office.num_of_seats = 2.5
        expect(office).to_not be_valid
      end

      it 'is not valid when num_of_seats is a string' do
        office.num_of_seats = 'abc'
        expect(office).to_not be_valid
      end

      it 'is not valid when num_of_seats is less than 1' do
        office.num_of_seats = 0
        expect(office).to_not be_valid
      end
    end
  end

  describe 'needs_vice validations' do
    context 'positive validations' do
      it 'is valid when needs_vice is present' do
        office.needs_vice = false
        expect(office).to be_valid
      end

      it 'is valid when needs_vice is true or false' do
        office.needs_vice = true
        expect(office).to be_valid
      end
    end

    context 'negative validations' do
      it 'is not valid when needs_vice is nil' do
        office.needs_vice = nil
        expect(office).to_not be_valid
      end
    end
  end
end
