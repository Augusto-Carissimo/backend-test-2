FactoryBot.define do
  factory :user do
    sequence(:name) { |n| "Usuario #{n}" }
    sequence(:email) { |n| "usuario#{n}@example.com" }
    department { "Engineering" }
    max_capacity_allowed { 10 }
    is_admin { false }

    trait :admin do
      is_admin { true }
    end

    trait :limited do
      max_capacity_allowed { 5 }
    end
  end
end
