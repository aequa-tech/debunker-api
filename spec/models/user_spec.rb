# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { create(:user) } # Assuming you have a User factory

  describe 'associations' do
    it { should have_many(:api_keys).dependent(:destroy) }
    it { should belong_to(:role) }
  end

  describe 'validations' do
    it { should validate_presence_of(:email) }
    it 'email is unique' do
      user = create(:user)
      new_user = build(:user, email: user.email)
      expect(new_user).not_to be_valid
    end
    it { should validate_presence_of(:name) }
  end

  describe '#info_attributes' do
    it 'returns a hash with name, email, and role' do
      expect(user.info_attributes.keys).to contain_exactly('name', 'email', 'role')
    end
  end

  describe '#active_api_keys' do
    it 'returns active api keys' do
      active_api_key = create(:api_key, user:)
      expect(user.active_api_keys).to include(active_api_key)
    end
  end

  describe '#set_default_role' do
    before { create(:role, :basic) }

    it 'sets the default role to user' do
      new_user = User.new
      expect(new_user.role.name).to eq('Basic')
      expect(new_user.role.role_type).to eq('user')
    end
  end
end
