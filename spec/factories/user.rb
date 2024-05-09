# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.email }

    trait :admin do
      role { 'admin' }
    end

    trait :confirmed do
      confirmed_at { Time.current }
    end

    trait :with_api_keys do
      after(:create) do |user|
        create_list(:api_key, 2, user:)
      end
    end
  end
end
