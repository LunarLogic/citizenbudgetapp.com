class OptionsParser
  def self.parse(raw_options:, widget_type:, minimum_units:, maximum_units:, step:)
    if %w(scaler slider).include?(widget_type) && minimum_units.present? && maximum_units.present? && step.present?
      options = (minimum_units.to_f..maximum_units.to_f).step(step.to_f).map(&:to_s)
      options  << maximum_units.to_s unless options.last == maximum_units
      options
    elsif widget_type == 'onoff'
      options = [BigDecimal(0), BigDecimal(1)].map(&:to_s)
    elsif %w(checkboxes option radio select).include?(widget_type) && raw_options.present?
      options = raw_options.split("\n").map(&:strip).reject(&:empty?)
    else
      options = []
    end
  end
end
