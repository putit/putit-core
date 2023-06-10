# == Schema Information
#
# Table name: hosts
#
#  id         :integer          not null, primary key
#  fqdn       :string           not null
#  name       :string
#  ip         :string
#  env_id     :integer
#  deleted_at :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Host < ActiveRecord::Base
  acts_as_paranoid

  validates_presence_of :name
  validates_format_of :name, with: /\A[\w\.-]+\Z/

  validates_presence_of :ip
  validates_format_of :ip, with: Resolv::IPv4::Regex

  validates_presence_of :fqdn
  validates_uniqueness_of :fqdn, scope: :env_id
  validates :fqdn, hostname: { allow_underscore: true }

  has_one :host_credential
  has_one :credential, through: :host_credential

  belongs_to :env

  def serializable_hash(_options = {})
    { id: id,
      fqdn: fqdn,
      name: name,
      ip: ip }
  end
end
