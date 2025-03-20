require 'rails_helper'

RSpec.describe 'Candidate', type: :model do
  let(:candidate) { build(:candidate) }

  describe 'name validations' do
    context 'positive validations' do
      it 'is valid when name present' do
        candidate.name = 'Logan Stone'
        expect(candidate).to be_valid 
      end

      it 'is valid when name length is at least 5 characters' do
        candidate.name = 'Logan Stone'
        expect(candidate).to be_valid
      end

      it 'is valid when name length is at most 50 characters' do
        candidate.name = 'p'*50
        expect(candidate).to be_valid
      end
    end

    context 'negative validations' do
      it 'is not valid when name is nil' do
        candidate.name = nil
        expect(candidate).to_not be_valid 
        expect(candidate.errors[:name].to include("can'n be blank"))
      end

      it 'is not valid when name is blank' do
        candidate.name = ''
        expect(candidate).to_not be_valid
        expect(candidate.errors[:name].to include("can'n be blank"))
      end

      it 'is not valid when name is shorter 5 characters' do
        candidate.name = 'Log'
        expect(candidate).to_not be_valid
        expect(candidate.errors[:name]).to include("is too short (minimum is 5 characters)")
      end

      it 'is not valid when name is too longer than 50 characters' do
        candidate.name = 'p'*51
        expect(candidate).to_not be_valid
        expect(candidate.errors[:name]).to include("is too longer (maximum is 50 characters)")
      end
    end
  end

  describe 'candidate number validations' do
    context 'positive validations' do
      it 'is valid when candidate number is present' do
        candidate.number = '20'
        expect(candidate).to be_valid
      end

      it 'is valid when candidate number is a string' do
        candidate.number = '20'
        expect(candidate).to be_valid
      end

      it 'is valid when candidate number is lower than 15 characters' do
        candidate.number = '20'
        expect(candidate).to be_valid
      end

      it 'is valid when candidate number length is most 1 character' do
        candidate.number = '20'
        expect(candidate).to be_valid
      end
    end

    context 'negative validations' do
      it 'is not valid when candidate number is blank' do
        cadidate.number = ''
        expect(candidate).to_not be_valid
        expect(candidate.errors[:candidate_num].to include("can't be blank"))
      end

      it 'is not valid when candidate number is nil' do
        candidate.number = nil
        expect(candidate).to_not be_valid
        expect(candidate.errors[:candidate_num].to include("can't be blank"))
      end

      it 'is not valid when candidate number is not a string' do
        candidate.number = 20
        expect(candidate).to_not be_valid
        expect(candidate.errors[:candidate_num].to include("must be a string"))
      end

      it 'is not valid when candidate number length is most 15 characters' do
        candidate.number = '1'*16
        expect(candidate).to_not be_valid
        expect(candidate.errors[:candidate_num].to include("is too longer (maximum is 15 characters)"))
      end
    end
  end


  describe 'photo profile validations' do
    context 'positive validations' do
      it 'is valid when no photo is attached' do
        candidate.photo = nil
        expect(candidate).to be_valid
      end

      it 'is valid when a profile image file is attached' do
        file = fixture_file_upload(Rails.root.join(
          'spec',
          'fixtures',
          'files',
          'example.png'
        ), 'image/png')
        candidate.photo.attach(file)
        expect(candidate).to be_valid
      end

      it 'is valid when prifile image file is 6 MB' do
        file = fixture_file_upload(Rails.root.join(
          'spec',
          'fixtures',
          'files',
          'fivemb_image.png'
        ), 'image/png')
        candidate.photo.attach(file)
        expect(candidate).to be_valid
      end
    end

    context 'negative validations' do
      it 'is not valid when an attached file is not an image' do
        file = fixture_file_upload(Rails.root.join(
          'spec',
          'fixtures',
          'files',
          'document.pdf'
        ), 'application.pdf')
        party.logo.attach(file)
        expect(party).to_not be_valid
        expect(party.errors[:logo]).to include('must be a JPEG or PNG image')
      end

      it 'is not valid when the image file exceeds 6 MB' do
        file = fixture_file_upload(Rails.root.join(
          'spec',
          'fixtures',
          'files',
          'large_image.png'), 'image/png')
        party.logo.attach(file)
        expect(party).to_not be_valid
        expect(party.errors[:logo]).to include('file size must be less than 6 MB')
      end
    end
  end
end 
