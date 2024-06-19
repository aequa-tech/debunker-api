require 'rails_helper'

RSpec.describe Role, type: :model do
  let(:role) { create(:role) } # Assuming you have a Role factory

  describe 'associations' do
    it { should have_many(:users).dependent(:nullify) }
    it { should belong_to(:tier) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }

    it 'name is unique' do
      role
      new_role = build(:role, name: role.name)
      expect(new_role).to_not be_valid
    end

    it 'is valid with valid attributes' do
      role = Role.new(name: 'Admin', role_type: :admin, tier: create(:tier))
      expect(role).to be_valid
    end

    it 'is not valid without a name' do
      role = Role.new(name: nil)
      expect(role).to_not be_valid
    end
  end

  it 'sets the default role type to user' do
    role = Role.new
    expect(role.role_type).to eq('user')
  end
end
