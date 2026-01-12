class Captain::MediaInterpolationService
  PLACEHOLDER_REGEX = /\{\{\s*media\.([a-zA-Z0-9_-]+)\s*\}\}/

  def initialize(account:)
    @account = account
  end

  def interpolate(text)
    return text if text.blank?

    keys = text.scan(PLACEHOLDER_REGEX).flatten.map(&:downcase).uniq
    return text if keys.empty?

    assets_by_name = @account.captain_assets.where(name: keys).index_by(&:name)

    text.gsub(PLACEHOLDER_REGEX) do
      key = Regexp.last_match(1).downcase
      asset = assets_by_name[key]
      asset&.file_url || Regexp.last_match(0)
    end
  end
end
