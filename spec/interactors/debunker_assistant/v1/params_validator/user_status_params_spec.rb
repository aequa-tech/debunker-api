# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DebunkerAssistant::V1::ParamsValidator::UsersStatusParams do
  it 'does not fail' do
    expect(described_class.call({}).success?).to be_truthy
  end
end
