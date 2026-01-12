account = Account.first
if account
  unit = Captain::Unit.find_or_create_by!(name: 'Unidade Matriz', account: account) do |u|
    u.status = :active
  end
  puts "Unit ensure: #{unit.name} (ID: #{unit.id}) for Account #{account.id}"
else
  puts 'No account found!'
end
