# Usage: bundle exec rails runner scripts/debug_status_suites.rb

def ask_input(prompt)
  print "#{prompt}: "
  gets.chomp
end

puts "\n=== Custom Tool Debugger & Fixer ===\n"

# 1. Find the Tool
tool = Captain::CustomTool.where('title ILIKE ? OR endpoint_url ILIKE ?', '%Status Suites%', '%SuitesStatus%').first

unless tool
  puts '❌ Tool not found! Please check the name.'
  exit
end

puts "✅ Found Tool: #{tool.title} (ID: #{tool.id})"
puts "   Endpoint: #{tool.endpoint_url}"
puts "   Auth Type: #{tool.auth_type}"
puts "   Auth Config: #{tool.auth_config.inspect}"

# 2. Check for missing headers
missing_headers = []
%w[PLUG-PLAY-ID PLUG-PLAY-TOKEN].each do |header|
  missing_headers << header unless tool.auth_config['headers']&.key?(header)
end

if missing_headers.any?
  puts "\n⚠️  Missing Headers in Auth Config: #{missing_headers.join(', ')}"
  puts '   The tool is likely failing because these are missing.'

  puts "\nDo you want to add these headers now? (y/n)"
  response = ask_input('> ')

  if response.downcase == 'y'
    updated_headers = tool.auth_config['headers'] || {}

    missing_headers.each do |h|
      value = ask_input("   Enter value for #{h}")
      updated_headers[h] = value
    end

    tool.auth_config['headers'] = updated_headers

    # Also clean param_schema if they are there
    tool.param_schema.reject! { |p| missing_headers.include?(p['name']) } if tool.param_schema.is_a?(Array)

    if tool.save
      puts "\n✅ Tool updated successfully!"
      puts "   New Auth Config: #{tool.auth_config.inspect}"
    else
      puts "\n❌ Failed to save tool: #{tool.errors.full_messages.join(', ')}"
    end
  else
    puts 'Skipping update.'
  end
else
  puts "\n✅ Check passed: All expected headers seem to be present in config."
end

# 3. Test the Tool (Optional)
puts "\nDo you want to run a connection test? (y/n)"
if ask_input('> ').downcase == 'y'
  puts 'Running test...'
  # Create a dummy assistant context if needed or just use HttpTool directly
  # We need an assistant to init HttpTool, assume first one
  assistant = Captain::Assistant.first
  if assistant
    http_tool = Captain::Tools::HttpTool.new(assistant, tool)
    begin
      result = http_tool.test_perform({})
      puts "\n--- Test Result ---"
      puts "Success: #{result[:success]}"
      puts "Status: #{result[:status]}"
      puts "Body Preview: #{result[:body].to_s[0..200]}..."
    rescue StandardError => e
      puts "Error running test: #{e.message}"
    end
  else
    puts 'No assistant found to run context.'
  end
end

puts "\n=== Done ==="
