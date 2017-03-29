class Question < ActiveRecord::Base
  belongs_to :section
  has_many :answers

  composed_of :widget, mapping: [%w(widget_type type), %w(options options), %w(labels labels),
    %w(placeholder placeholder), %w(cols cols), %w(rows rows), %w(size size), %w(maxlength maxlength),
    %w(default_value default_value), %w(unit_amount unit_amount), %w(unit_name unit_name)]

  attr_accessor :raw_options, :raw_labels, :minimum_units, :maximum_units, :step
  delegate :raw_options, :raw_labels, :minimum_units, :maximum_units, :step,
    :budgetary?, :nonbudgetary?, :yes_no?, :multiple, :omit_amounts?, :minimum_amount,
    :maximum_amount, to: :widget

  validates :criteria, inclusion: { in: ->(q) { q.section.criterion } }, allow_blank: true
  validate :valid_widget

  before_save :strip_title_and_extra

  scope :budgetary, ->{ where('widget IN (?)', Widget::BUDGETARY) }
  scope :nonbudgetary, ->{ where('widget IN (?)', Widget::NONBUDGETARY) }
  default_scope ->{ order(position: :asc) }

  private

  def strip_title_and_extra
    self.title = title.strip if title?
    self.extra = extra.strip if extra?
  end

  def valid_widget
    errors.add(:widget) unless widget.valid?
  end
end
