# frozen_string_literal: true

FactoryBot.define do
  factory :role do
    name { 'Basic' }
    tier { Tier.find_by(name: 'Free') || create(:tier) }

    trait :admin do
      name { 'Admin' }
      role_type { :admin }
    end

    trait :basic do
      name { 'Basic' }
      role_type { :user }
    end
  end
end
