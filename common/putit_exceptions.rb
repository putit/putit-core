module PutitExceptions
  class EnumError < StandardError
    def initialize(msg = 'Something went wrong.')
      super
    end
  end

  class HostDNSError < StandardError
    def initialize(msg = 'Unable to resolve host IP address.')
      super
    end
  end

  class MakePlaybookServiceError < StandardError
    def initialize(msg = 'Unable to generate deployment playbook.')
      super
    end
  end

  class ArchivePlaybookServiceError < StandardError
    def initialize(msg = 'Unable to archive deployment playbook.')
      super
    end
  end

  class DuplicateDeploymentResult < StandardError
    def initialize(msg = 'Duplication of deployment result')
      super
    end
  end

  class SemanticTermError < StandardError
    def initialize(msg = 'Invalid semantic term.')
      super
    end
  end

  class SemanticNotValidVersion < StandardError
    def initialize(msg = 'It is not a valid semantic version.')
      super
    end
  end
end
