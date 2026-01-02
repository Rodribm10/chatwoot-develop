account = Account.first
if account
  puts "Current feature flags: #{account.feature_flags}"
  
  # Load features from YAML
  features_config = YAML.safe_load(Rails.root.join('config/features.yml').read)
  
  # Select features that should be enabled by default
  default_features = features_config.select { |f| f['enabled'] == true }.map { |f| f['name'] }
  
  puts "Enabling default features: #{default_features.join(', ')}"
  
  # Enable them
  account.enable_features!(*default_features)
  
  puts "New feature flags: #{account.feature_flags}"
  puts "Inbox Management Enabled? #{account.feature_enabled?('inbox_management')}"
else
  puts "Account not found!"
end
