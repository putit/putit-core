class ApprovalMailer
  require 'yaml'

  def self.deliver_approval_email(approval)
    return false if approval.sent?

    config = Settings.mailer
    r = approval.release_order.release
    approval.update_attribute(:sent, true)

    Pony.mail(to: approval.user.email,
              from: 'notifications@onlynet.com.pl',
              subject: "Please approve \"#{r.name}\"",
              body: ''"
Please approve following release \"#{r.name}\" using given link: \"http://#{Settings.putit_core_url}/approval/#{approval.uuid}\"
"'',
              via: :smtp,
              via_options: {
                address: (config[ENV['RACK_ENV']]['smtp_server']).to_s,
                port: (config[ENV['RACK_ENV']]['smtp_port']).to_s,
                user_name: (config[ENV['RACK_ENV']]['smtp_username']).to_s,
                password: (config[ENV['RACK_ENV']]['smtp_password']).to_s,
                authentication: (config[ENV['RACK_ENV']]['authentication']).to_s,
                domain: (config[ENV['RACK_ENV']]['domain']).to_s,
                openssl_verify_mode: 'none'
              })
  end
end
