namespace :captain do
  desc 'Report tool_key mismatches between code definitions and DB configs'
  task tool_key_audit: :environment do
    code_tools = Captain::Tools::Definitions::ALL.keys.map(&:to_s).sort
    db_tools = Captain::ToolConfig.distinct.pluck(:tool_key).compact.map(&:to_s).sort

    only_in_code = code_tools - db_tools
    only_in_db = db_tools - code_tools

    puts "Tools only in code (missing in DB configs):"
    puts only_in_code.any? ? only_in_code.join("\n") : 'none'
    puts
    puts "Tools only in DB configs (missing in code):"
    puts only_in_db.any? ? only_in_db.join("\n") : 'none'
  end
end
