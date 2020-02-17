class ArchivePlaybookService < PutitService
  include Util::Tar

  def initialize(release_order, logger_data = {})
    super
    @release_order = release_order
  end

  def run!
    dir = @release_order.release.playbook_dir

    begin
      io = tar(dir)
      gz = gzip(io)

      gz.binmode
      binary = Marshal.dump(gz.read)

      @release_order.update_attribute('archive', binary)
    rescue StandardError => e
      raise PutitExceptions::ArchivePlaybookServiceError, "Unable to archive deployment playbook at #{dir} due to: #{e.message}"
    end
  end
end
