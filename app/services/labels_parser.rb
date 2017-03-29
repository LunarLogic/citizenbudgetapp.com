class LabelsParser
  def self.parse(raw_labels:, widget_type:)
    if %w(onoff option).include?(widget_type) && raw_labels.present?
      RawListParser.parse(raw_labels)
    end
  end
end
