# == Schema Information
#
# Table name: host_applications
#
#  id             :integer          not null, primary key
#  host_id        :integer          indexed
#  application_id :integer          indexed
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_host_applications_on_application_id  (application_id)
#  index_host_applications_on_host_id         (host_id)
#

class HostApplication < ActiveRecord::Base
  belongs_to :host
  belongs_to :application
end
