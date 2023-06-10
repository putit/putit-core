# == Schema Information
#
# Table name: host_applications
#
#  id             :integer          not null, primary key
#  host_id        :integer
#  application_id :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class HostApplication < ActiveRecord::Base
  belongs_to :host
  belongs_to :application
end
