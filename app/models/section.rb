class Section < ActiveRecord::Base
  GROUPS = %w(simulator custom other)

  belongs_to :questionnaire
  has_many :questions

  validates :group, presence: true
  validates :group, inclusion: { in: GROUPS, allow_blank: true }

  after_initialize :set_default_group

  scope :simulator, ->{ where(group: ['simulator', 'custom']) }
  scope :budgetary, ->{ where(group: 'simulator') }
  scope :nonbudgetary, ->{ where(group: 'other') }
  default_scope ->{ order(position: :asc) }

  # @return [String] the name to display in the administrative interface
  def name
    title? && title || I18n.t(:untitled)
  end

  # @return [Boolean] whether all questions are nonbudgetary questions
  def nonbudgetary?
    questions.all? {|q| q.widget.nonbudgetary?}
  end

  # @param text [String]
  def criterion_as_list=(text)
    self.criterion = text.split("\n").map(&:strip).reject(&:empty?)
  end

  def criterion_as_list
    criterion.join("\n")
  end


  private

  def set_default_group
    self.group ||= 'simulator'
  end
end
