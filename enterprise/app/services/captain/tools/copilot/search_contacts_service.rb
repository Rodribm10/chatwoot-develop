class Captain::Tools::Copilot::SearchContactsService < Captain::Tools::BaseTool
  def self.name
    'search_contacts'
  end

  description 'Search contacts based on query parameters'
  param :email, type: :string, desc: 'Filter contacts by email'
  param :phone_number, type: :string, desc: 'Filter contacts by phone number'
  param :name, type: :string, desc: 'Filter contacts by name (partial match)'

  def execute(*args, **params)
    actual_params = resolve_params(args, params)
    email = actual_params[:email]
    phone_number = actual_params[:phone_number]
    name = actual_params[:name]
    contacts = Contact.where(account_id: @assistant.account_id)
    contacts = contacts.where(email: email) if email.present?
    contacts = contacts.where(phone_number: phone_number) if phone_number.present?
    contacts = contacts.where('LOWER(name) ILIKE ?', "%#{name.downcase}%") if name.present?

    return 'No contacts found' unless contacts.exists?

    contacts = contacts.limit(100)

    <<~RESPONSE
      #{contacts.map(&:to_llm_text).join("\n---\n")}
    RESPONSE
  end

  def active?
    user_has_permission('contact_manage')
  end
end
