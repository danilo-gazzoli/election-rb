# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Party, type: :model do
  let(:party) { build(:party) }

  describe 'name validations' do
    context 'positive cases' do
      it 'is valid when name is present' do
        party.name = 'Partido Exemplo X'
        expect(party).to be_valid
      end

      it 'is valid when name length is at least 10 characters' do
        party.name = 'Partido Teste'
        expect(party).to be_valid
      end

      it 'is valid when name length is at most 50 characters' do
        party.name = 'P' * 50
        expect(party).to be_valid
      end
    end

    context 'negative cases' do
      it 'is not valid when name is nil' do 
        party.name = nil
        expec(party).to_not be_valid
        expect(party.errors[:name]).to include("can't be nil")
      end

      it 'is not valid when name is blank' do
        party.name = ''
        expect(party).to_not be_valid
        expect(party.errors[:name]).to include("can't be blank")
      end

      it 'is not valid when name is shorter than 10 characters' do
        party.name = 'Partido'
        expect(party).to_not be_valid
        expect(party.errors[:name]).to include("is too short (minimum is 10 characters)")
      end

      it 'is not valid when name is longer than 50 characters' do
        party.name = 'P' * 51
        expect(party).to_not be_valid
        expect(party.errors[:name]).to include("is too long (maximum is 50 characters)")
      end

      it 'is not valid if the name is not unique' do
        create(:party, name: 'UNIQUE PARTY')
        duplicate = build(:party, name: 'UNIQUE PARTY')
        expect(duplicate).to_not be_valid
        expect(duplicate.errors[:name]).to include("has already been taken")
      end
    end
  end

  describe 'abbreviation validations' do
    context 'positive cases' do
      it 'is valid when abbreviation is present' do
        party.abbreviation = 'PT'
        expect(party).to be_valid
      end

      it 'is valid when abbreviation has between 2 and 8 uppercase letters' do
        party.abbreviation = 'ABCDEFG'
        expect(party).to be_valid
      end
    end

    context 'negative cases' do
      it 'is not valid when abbreviation is nil' do 
        party.abbreviation = nil
        expec(party).to_not be_valid
        expect(party.errors[:abbreviation]).to include("can't be nil")
      end

      it 'is not valid when abbreviation is blank' do
        party.abbreviation = ''
        expect(party).to_not be_valid
        expect(party.errors[:abbreviation]).to include("can't be blank")
      end

      it 'is not valid when abbreviation contains lowercase letters' do
        party.abbreviation = 'Pt'
        expect(party).to_not be_valid
        expect(party.errors[:abbreviation]).to include("is invalid")
      end

      it 'is not valid when abbreviation is shorter than 2 characters' do
        party.abbreviation = 'A'
        expect(party).to_not be_valid
        expect(party.errors[:abbreviation]).to include("is too short (minimum is 2 characters)")
      end

      it 'is not valid when abbreviation is longer than 8 characters' do
        party.abbreviation = 'ABCDEFGHI'
        expect(party).to_not be_valid
        expect(party.errors[:abbreviation]).to include("is too long (maximum is 8 characters)")
      end

      it 'is not valid if the abbreviation is not unique' do
        create(:party, abbreviation: 'UNI')
        duplicate = build(:party, abbreviation: 'UNI')
        expect(duplicate).to_not be_valid
        expect(duplicate.errors[:abbreviation]).to include("has already been taken")
      end
    end
  end

  describe 'party_number validations' do
    context 'positive cases' do
      it 'is valid when party_number is present and within 1 to 99' do
        party.party_number = 13
        expect(party).to be_valid
      end

      it 'is valid when party_number is the minimum value (1)' do
        party.party_number = 1
        expect(party).to be_valid
      end

      it 'is valid when party_number is the maximum value (99)' do
        party.party_number = 99
        expect(party).to be_valid
      end
    end

    context 'negative cases' do
      it 'is not valid when party_number is blank' do
        party.party_number = nil
        expect(party).to_not be_valid
        expect(party.errors[:party_number]).to include("can't be blank")
      end

      it 'is not valid when party_number is not an integer' do
        party.party_number = 13.5
        expect(party).to_not be_valid
        expect(party.errors[:party_number]).to include("must be an integer")
      end

      it 'is not valid when party_number is less than 1' do
        party.party_number = 0
        expect(party).to_not be_valid
        expect(party.errors[:party_number]).to include("must be greater than or equal to 1")
      end

      it 'is not valid when party_number is greater than 99' do
        party.party_number = 100
        expect(party).to_not be_valid
        expect(party.errors[:party_number]).to include("must be less than or equal to 99")
      end

      it 'is not valid if party_number is not unique' do
        create(:party, party_number: 45)
        duplicate = build(:party, party_number: 45)
        expect(duplicate).to_not be_valid
        expect(duplicate.errors[:party_number]).to include("has already been taken")
      end
    end
  end

  describe 'description validations' do
    context 'positive cases' do
      it 'is valid when description is not provided (optional)' do
        party.description = nil
        expect(party).to be_valid
      end

      it 'is valid when description is provided and within 15 to 500 characters' do
        party.description = 'A' * 20
        expect(party).to be_valid
      end
    end

    context 'negative cases' do
      it 'is not valid when description is provided but shorter than 15 characters' do
        party.description = 'Too short'
        expect(party).to_not be_valid
        expect(party.errors[:description]).to include("is too short (minimum is 15 characters)")
      end

      it 'is not valid when description is longer than 500 characters' do
        party.description = 'A' * 501
        expect(party).to_not be_valid
        expect(party.errors[:description]).to include("is too long (maximum is 500 characters)")
      end
    end
  end

  describe 'logo validations' do
    context 'positive cases' do
      it 'is valid when no logo is attached (optional)' do
        party.logo = nil
        expect(party).to be_valid
      end

      it 'is valid when a proper image file is attached' do
        file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'exemple.png'), 'image/png')
        party.logo.attach(file)
        expect(party).to be_valid
      end

      it 'is valid when the image file is 5 MB' do
        file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'fivemb_image.png'), 'image/png')
        party.logo.attach(file)
        expect(party).to be_valid
      end
    end

    context 'negative cases' do
      it 'is not valid when an attached file is not an image' do
        file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'document.pdf'), 'application/pdf')
        party.logo.attach(file)
        expect(party).to_not be_valid
        expect(party.errors[:logo]).to include("must be a JPEG or PNG image")
      end

      it 'is not valid when the image file exceeds 5 MB' do
        # Supondo que exista um arquivo fixture com tamanho maior que 5 MB
        file = fixture_file_upload(Rails.root.join('spec', 'fixtures', 'files', 'large_image.png'), 'image/png')
        party.logo.attach(file)
        expect(party).to_not be_valid
        expect(party.errors[:logo]).to include("file size must be less than 5 MB")
      end
    end
  end
end

