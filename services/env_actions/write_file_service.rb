class WriteFileService
  def initialize(event)
    path, content = event.data.values_at(:path, :content)
    File.write(path, content)
  end
end
