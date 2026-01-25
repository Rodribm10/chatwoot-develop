FactoryBot.define do
  factory :jasmine_inbox_config, class: 'Jasmine::InboxConfig' do
    association :account
    association :inbox
    name { 'Test Jasmine' }
    is_enabled { true }
  end

  factory :jasmine_collection, class: 'Jasmine::Collection' do
    association :account
    sequence(:name) { |n| "Collection #{n}" }
    visibility { :private }

    trait :private do
      visibility { :private }
      association :owner_inbox, factory: :inbox
    end

    trait :shared do
      visibility { :shared }
      owner_inbox { nil }
    end
  end

  factory :jasmine_inbox_collection, class: 'Jasmine::InboxCollection' do
    association :account
    association :inbox
    association :collection, factory: :jasmine_collection
    priority { 0 }
  end

  factory :jasmine_document, class: 'Jasmine::Document' do
    association :account
    association :collection, factory: :jasmine_collection
    content { 'Sample Content' }
  end
end
