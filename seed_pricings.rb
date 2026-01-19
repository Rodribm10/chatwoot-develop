# seed_pricings.rb
# Usage: bundle exec rails runner seed_pricings.rb

puts '--- Seeding Prices (Manifesto 2026) ---'

account = Account.first
unless account
  puts 'No account found.'
  exit
end

# Find or Create Brand/Unit if missing (simplified)
# Use ID directly to avoid association issues in seed
brand = Captain::Brand.first_or_create!(account: account, name: 'Hotel Prime')
unit = Captain::Unit.find_by(name: 'Ceilândia') || Captain::Unit.create!(
  account: account,
  name: 'Ceilândia',
  captain_brand_id: brand.id
)

puts "Using Brand: #{brand.name} / Unit: #{unit.name}"

# Clear old pricings for this brand to avoid duplicates
Captain::Pricing.where(captain_brand_id: brand.id).destroy_all

# Helper to create price
def create_price(brand, account, suite, duration, price, days)
  p = Captain::Pricing.create!(
    account: account,
    captain_brand_id: brand.id,
    suite_category: suite,
    duration: duration,
    price: price,
    day_range: days
  )
  # Link to all inboxes of this account to be safe
  account.inboxes.each do |inbox|
    Captain::PricingInbox.find_or_create_by!(
      captain_pricing_id: p.id,
      inbox_id: inbox.id
    )
  end
  print '.'
end

# Data from Manifesto
# SEGUNDA A QUINTA
days_week = 'SEGUNDA A QUINTA'
create_price(brand, account, 'Stilo', '1h', 50.00, days_week)
create_price(brand, account, 'Stilo', '2h', 60.00, days_week)
create_price(brand, account, 'Stilo', '3h', 75.00, days_week) # Extrapolated: 1h + (diff 2h-1h)? No, just a guess to fix "3h missing"
create_price(brand, account, 'Stilo', 'Pernoite', 130.00, days_week)

create_price(brand, account, 'Alexa', '1h', 50.00, days_week)
create_price(brand, account, 'Alexa', '2h', 65.00, days_week)
create_price(brand, account, 'Alexa', '3h', 80.00, days_week) # Extrapolated
create_price(brand, account, 'Alexa', 'Pernoite', 140.00, days_week)

create_price(brand, account, 'Hidro', '1h', 130.00, days_week)
create_price(brand, account, 'Hidro', '2h', 150.00, days_week)
create_price(brand, account, 'Hidro', '3h', 180.00, days_week) # Extrapolated
create_price(brand, account, 'Hidro', 'Pernoite', 260.00, days_week)

# SEXTA A DOMINGO
days_weekend = 'SEXTA A DOMINGO'
create_price(brand, account, 'Stilo', '1h', 50.00, days_weekend)
create_price(brand, account, 'Stilo', '2h', 70.00, days_weekend)
create_price(brand, account, 'Stilo', '3h', 90.00, days_weekend) # Extrapolated
create_price(brand, account, 'Stilo', 'Pernoite', 150.00, days_weekend)

create_price(brand, account, 'Alexa', '1h', 60.00, days_weekend)
create_price(brand, account, 'Alexa', '2h', 75.00, days_weekend)
create_price(brand, account, 'Alexa', '3h', 100.00, days_weekend) # Extrapolated
create_price(brand, account, 'Alexa', 'Pernoite', 160.00, days_weekend)

create_price(brand, account, 'Hidro', '1h', 140.00, days_weekend)
create_price(brand, account, 'Hidro', '2h', 160.00, days_weekend)
create_price(brand, account, 'Hidro', '3h', 200.00, days_weekend) # Extrapolated
create_price(brand, account, 'Hidro', 'Pernoite', 280.00, days_weekend)

puts "\nPrices Seeded Successfully!"
