# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    role { Role.find_by(name: 'Basic') || create(:role, :basic) }

    trait :admin do
      role { Role.find_by(name: 'Admin') || create(:role, :admin) }
    end

    trait :confirmed do
      confirmed_at { Time.current }
    end

    trait :with_api_key do
      after(:create) do |user|
        create_list(:api_key, 1, user:)
      end
    end
  end
end
