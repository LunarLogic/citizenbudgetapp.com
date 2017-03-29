class RawListParser
  def self.parse(raw_list)
    raw_list.split("\n").map(&:strip).reject(&:empty?)
  end
end
