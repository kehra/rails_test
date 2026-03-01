class NormalizedStringType < ActiveModel::Type::String
  def cast(value)
    super(value).to_s.squish.presence
  end
end
