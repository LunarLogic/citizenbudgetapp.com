class Widget
  include ActiveModel::Model
  include ActiveModel::Serialization

  TYPES = %w(checkbox checkboxes onoff radio option readonly scaler select slider static text textarea)
  BUDGETARY = %w(onoff option scaler slider)
  NONBUDGETARY = %w(checkbox checkboxes radio readonly select static text textarea)

  validates :type, inclusion: { in: TYPES }

  # HTML attribute validations
  validates :size, :maxlength, numericality: { greater_than: 0, only_integer: true }, allow_nil: true, if: ->(w){type == 'text'}
  validates :rows, :cols, numericality: { greater_than: 0, only_integer: true }, allow_nil: true,      if: ->(w){type == 'textarea'}

  # Budgetary widget validations
  validates :unit_amount,   presence: true,                      if: ->(w){%w(onoff option scaler slider static).include?(type)}
  validates :default_value, presence: true,                      if: ->(w){%w(onoff option scaler slider).include?(type)}
  validates :unit_amount,   numericality: true, allow_nil: true, if: ->(w){%w(onoff option scaler slider static).include?(type)}
  validates :default_value, numericality: true, allow_nil: true, if: ->(w){%w(onoff option scaler slider).include?(type)}
  validates :options,       presence: true,                      if: ->(w){%w(checkboxes onoff option radio scaler select slider).include?(type)}
  validates :labels,        presence: true,                      if: ->(w){type == 'option'}

  # Slider validations
  validates :minimum_units, :maximum_units, :step, presence: true,                                     if: ->(w){%w(scaler slider).include?(type)}
  validates :minimum_units, :maximum_units,        numericality: true, allow_nil: true,                if: ->(w){%w(scaler slider).include?(type)}
  validates :step,                                 numericality: { greater_than: 0 }, allow_nil: true, if: ->(w){%w(scaler slider).include?(type)}

  validate :maximum_units_must_be_greater_than_minimum_units,                    if: ->(w){%w(scaler slider).include?(type)}
  validate :default_value_must_be_between_minimum_and_maximum,                   if: ->(w){%w(scaler slider).include?(type)}
  validate :default_value_must_be_an_option,                                     if: ->(w){%w(scaler slider option).include?(type)}
  validate :options_and_labels_must_agree,                                       if: ->(w){type == 'option'}

  attr_accessor :type
  attr_accessor :options, :labels, :default_value, :size, :maxlength, :placeholder, :rows, :cols, :unit_amount, :unit_name
  attr_accessor :minimum_units, :maximum_units, :step
  attr_reader :readonly # ?


  # @param type [String]
  # @param options [Array]
  # @param labels [Array]
  # @param placeholder [String]
  # @param cols [Integer]
  # @param rows [Integer]
  # @param size [Integer]
  # @param maxlength [Integer]
  # @param default_value [BigDecimal]
  # @param unit_amount [BigDecimal]
  # @param unit_name [String]
  def initialize(type, options=[], labels=[], placeholder=nil, cols=nil, rows=nil, size=nil, maxlength=nil, default_value=nil, unit_amount=nil, unit_name=nil)
    super(type: type, options: options, labels: labels, placeholder: placeholder,
      cols: cols, rows: rows, size: size, maxlength: maxlength, default_value: default_value,
      unit_amount: unit_amount, unit_name: unit_name)

    case type
    when *%w(scaler slider)
      raise ArgumentError.new('options must contain at least 2 elements') unless options.many?
    end

    set_virtual_attributes!

    self
  end

  # @return [String, nil]
  def raw_options
    options.join("\n") if %w(checkboxes option radio select).include?(type)
  end

  # @return [String, nil]
  def raw_labels
    labels.join("\n") if %w(onoff option).include?(type)
  end

  # @return [Boolean] whether it is a nonbudgetary question
  def nonbudgetary?
    NONBUDGETARY.include?(type)
  end

  # @return [Boolean] whether it is a budgetary question
  def budgetary?
    BUDGETARY.include?(type)
  end

  # @return [Boolean] whether multiple values can be selected
  def multiple?
    type == 'checkboxes'
  end

  # @return [Boolean] whether to omit slider labels
  def omit_amounts?
    (unit_name == '$' && unit_amount.abs == 1) || (type == 'scaler' && section.questionnaire.mode == 'taxes')
  end

  # @return [Boolean] whether it is a yes-no question
  def yes_no?
    unit_name.blank? && minimum_units == 0 && maximum_units == 1 && step == 1
  end

  # @return [Boolean] whether the widget is checked by default
  def checked?
    %w(checkbox onoff).include?(type) && default_value == 1
  end

  # @return [Boolean] whether the widget is unchecked by default
  def unchecked?
    %w(checkbox onoff).include?(type) && default_value == 0
  end

  # @return [Boolean] whether the widget option is selected by default
  def selected?(option)
    type == 'option' && default_value == BigDecimal(option)
  end

  # @return [BigDecimal] the maximum value of the widget
  def maximum_amount
    case type
    when *%w(onoff scaler slider)
      unit_amount ? (maximum_units - default_value) * unit_amount : maximum_units
    when 'option'
      options.max {|o| BigDecimal(o)}
    else
      # TODO: what with other types? Is this good approach?
      BigDecimal(0)
    end
  end

  # @return [BigDecimal] the minimum value of the widget
  def minimum_amount
    case type
    when *%w(onoff scaler slider)
      unit_amount ? (minimum_units - default_value) * unit_amount : minimum_units
    when 'option'
      options.min {|o| BigDecimal(o)}
    else
      # TODO: what with other types? Is this good approach?
      BigDecimal(0)
    end
  end

  # @return [Hash]
  def attributes
    atrs = [:type, :options, :labels, :default_value, :size, :maxlength, :placeholder, :rows, :cols, :unit_amount, :unit_name]
    Hash[atrs.map {|a| [a, send(a)] }]
  end

  private

  def set_virtual_attributes!
    case type
    when *%w(scaler slider)
      self.minimum_units = BigDecimal(options.first)
      self.maximum_units = BigDecimal(options.last)
      self.step = (BigDecimal(options[1]) - BigDecimal(options[0])).round(4)
    when 'onoff'
      self.minimum_units = BigDecimal(0)
      self.maximum_units = BigDecimal(1)
      self.step = BigDecimal(1)
    # when 'option' REALLY?
    #   @unit_amount = BigDecimal(1)
    end
  end

  def maximum_units_must_be_greater_than_minimum_units
    if minimum_units.present? && maximum_units.present? && minimum_units > maximum_units
      errors.add :maximum_units, I18n.t('errors.messages.maximum_units_must_be_greater_than_minimum_units')
    end
  end

  def default_value_must_be_between_minimum_and_maximum
    if minimum_units.present? && maximum_units.present? && default_value.present? && minimum_units < maximum_units
      if default_value < minimum_units || default_value > maximum_units
        errors.add :default_value, I18n.t('errors.messages.default_value_must_be_between_minimum_and_maximum')
      end
    end
  end

  def default_value_must_be_an_option
    unless options.map {|o| BigDecimal(o)}.include?(default_value)
      if options.present? && default_value.present?
        errors.add :default_value, I18n.t('errors.messages.default_value_must_be_an_option')
      end
    end
  end

  def options_and_labels_must_agree
    if labels.any? && options.any?
      unless labels.size == options.size
        errors.add :labels_as_list, I18n.t('errors.messages.options_and_labels_must_agree')
      end
    end
  end
end
