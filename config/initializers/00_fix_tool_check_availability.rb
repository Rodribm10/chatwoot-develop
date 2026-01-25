# TEMPORARY FIX: Enable CheckAvailabilityTool on startup
# This ensures the tool is enabled even if the console environment is broken.

Rails.application.config.after_initialize do
  puts '--- [FIX] Verifying CheckAvailabilityTool Config ---'

  begin
    assistant = Captain::Assistant.first
    if assistant
      tool_key = 'check_availability'
      config = assistant.tool_configs.find_or_initialize_by(tool_key: tool_key)

      if config.new_record? || !config.is_enabled
        config.is_enabled = true
        config.save!
        puts "--- [FIX] SUCCESS: check_availability ENABLED for #{assistant.name} ---"
      else
        puts "--- [FIX] SKIPPED: Already enabled for #{assistant.name} ---"
      end
    else
      puts '--- [FIX] WARNING: No Assistant found to fix. ---'
    end
  rescue StandardError => e
    puts "--- [FIX] ERROR: #{e.message} ---"
  end
end
