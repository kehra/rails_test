class TaskImportForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations::Callbacks

  attribute :title, NormalizedStringType.new
  attribute :description, NormalizedStringType.new
  attribute :due_on, :date

  before_validation :normalize_title

  validates :title, presence: true
  validates :due_on, comparison: { greater_than_or_equal_to: Date.current }, allow_nil: true

  def to_task_attributes
    return {} unless valid?

    {
      title: title,
      description: description,
      due_on: due_on,
      status: :todo,
      priority: :normal
    }
  end

  private

  def normalize_title
    self.title = title.to_s.strip
  end
end
