class Captain::Llm::ContactIdentityService
  NAME_PATTERNS = [
    /(?:meu nome e|meu nome é|me chama de|pode me chamar de|aqui e|aqui é|sou o|sou a)\s+([A-Za-zÀ-ÿ'\- ]{2,40})/i,
    /(?:pode me chamar de|me chama de)\s+([A-Za-zÀ-ÿ'\- ]{2,40})/i,
    /(?:me chamo|eu sou)\s+([A-Za-zÀ-ÿ'\- ]{2,40})/i
  ].freeze

  CORRECTION_PATTERNS = [
    /(?:me chama de|pode me chamar de|me chamo)\s+([A-Za-zÀ-ÿ'\- ]{2,40})/i
  ].freeze

  def initialize(contact:, message_content:)
    @contact = contact
    @message_content = message_content.to_s.strip
  end

  def extract_and_update
    return if @contact.blank? || @message_content.blank?

    name = extract_name
    return if name.blank?

    attributes = @contact.additional_attributes || {}
    existing_confidence = attributes['name_confidence'].to_f
    is_correction = correction_message?

    return if existing_confidence >= 0.8 && !is_correction

    attributes['preferred_name'] = normalize_name(name)
    attributes['name_confidence'] = 0.95
    attributes['name_source'] = 'user_claimed'
    attributes['last_confirmed_at'] = Time.current.iso8601
    @contact.update!(additional_attributes: attributes)
  end

  private

  def extract_name
    match = nil
    NAME_PATTERNS.each do |pattern|
      match = @message_content.match(pattern)
      break if match
    end
    return nil unless match

    candidate = match[1].to_s.strip
    candidate = candidate.split(/\b(e|eh|é)\b/i).first.to_s.strip
    candidate = candidate.gsub(/[^\p{L}\s'\-]/, '').strip
    return nil if candidate.length < 2
    return nil if candidate.split.size > 3

    candidate
  end

  def correction_message?
    CORRECTION_PATTERNS.any? { |pattern| @message_content.match?(pattern) }
  end

  def normalize_name(name)
    parts = name.split
    parts.shift if parts.first&.downcase.in?(%w[a o])
    parts.map(&:capitalize).join(' ')
  end
end
