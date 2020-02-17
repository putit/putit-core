class ApprovalController < SecureController
  get '/:uuid' do |uuid|
    status 202

    approval = Approval.find_by_uuid(uuid)
    if approval.nil?
      request_halt("Unable to find approval link for uuid: #{uuid}", 404)
    else
      approval.update!(accepted: true)
      logger.info("Approved: #{uuid}")
    end

    { status: 'ok' }.to_json
  end
end
