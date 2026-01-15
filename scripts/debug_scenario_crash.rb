# scripts/debug_scenario_crash.rb
ENV['RAILS_ENV'] ||= 'development'
require_relative '../config/environment'

puts 'Starting Debug Script...'

# Find the scenario
scenario = Captain::Scenario.where('title ILIKE ?', '%Daniela%').first
unless scenario
  puts "Scenario 'Daniela' not found. Listing available scenarios:"
  Captain::Scenario.all.each { |s| puts "- #{s.title} (ID: #{s.id})" }
  exit
end

puts "Found Scenario: #{scenario.title} (ID: #{scenario.id})"

# Mock user and conversation
conversation = Conversation.last
unless conversation
  puts 'No conversation found.'
  exit
end
user = conversation.contact

puts "Using Conversation: #{conversation.id} (Inbox: #{conversation.inbox_id})"
puts "Using Contact: #{user.name} (ID: #{user.id})"

# Initialize Tool
tool = Captain::Tools::ScenarioDelegatorTool.new(scenario, user: user, conversation: conversation)

puts 'Tool Initialized. Executing perform...'

begin
  # Simulate the call that triggers contact update
  input = { pergunta_interna: 'Meu nome é Rodrigo e meu CPF é 12345678900' }

  # Monkeypatch to bypass rescue block and see backtrace
  Captain::Tools::ScenarioDelegatorTool.class_eval do
    def perform_debug(args)
      pergunta_interna = args[:pergunta_interna]
      agent = @scenario.agent(user: @user, conversation: @conversation)
      puts "Agent Tools: #{agent.tools.map(&:name)}"

      runner = Agents::Runner.with_agents(agent)
      result = runner.run(pergunta_interna, max_turns: 5)

      puts "Runner Result: #{result.inspect}"
      result.output
    end
  end

  tool.perform_debug(input)

rescue StandardError => e
  puts "\nCRASH DETECTED!"
  puts "Error: #{e.message}"
  puts 'Backtrace:'
  puts e.backtrace.join("\n")
end
