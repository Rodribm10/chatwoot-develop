require 'yaml'
begin
  content = File.read('config/installation_config.yml')
  YAML.safe_load(content)
  puts 'installation_config.yml parsed successfully'
rescue StandardError => e
  puts "Error parsing installation_config.yml: #{e.class} - #{e.message}"
  puts e.backtrace
end

begin
  content = File.read('config/features.yml')
  YAML.safe_load(content)
  puts 'features.yml parsed successfully'
rescue StandardError => e
  puts "Error parsing features.yml: #{e.class} - #{e.message}"
  puts e.backtrace
end
