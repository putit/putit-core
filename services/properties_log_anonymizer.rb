class PropertiesAnonymizer
  def self.anonymize(properties)
    ANONYMIZE_PROPERTIES.each do |str|
      properties[str] = 'XXXXXXXX' if properties.key? str.to_s
    end
    properties
  rescue StandardError
    properties = {}
  end
end
