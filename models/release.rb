# == Schema Information
#
# Table name: releases
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  status     :integer
#  metadata   :string           default({})
#  deleted_at :datetime         indexed
#
# Indexes
#
#  index_releases_on_deleted_at  (deleted_at)
#

class Release < ActiveRecord::Base
  acts_as_paranoid

  include Putit::ActiveRecordLogging

  serialize :metadata, JSON

  validates_presence_of :name
  validates_format_of :name, with: /\A[\w. -]+\z/

  has_many :release_orders, dependent: :destroy
  has_many :subreleases
  has_many :dependent_releases, through: :subreleases, source: :subrelease

  enum status: %i[open closed]
  after_create :set_default_status

  scope :open, -> { where(status: :open) }

  # used in controller
  def get_orders(options = {})
    if options[:status] && options[:upcoming]
      release_orders.upcoming.where(status: options[:status])
    elsif options[:status] && !options.include?('upcoming')
      release_orders.where(status: options[:status])
    elsif options[:upcoming] && !options.include?('status')
      release_orders.upcoming
    else
      release_orders.all
    end
  end

  # has_paper_trail class_name: 'PaperTrailVersion'
  BASE_DIR = Settings.putit_playbooks_path || '/tmp/opt/putit/playbooks'

  def playbook_dir
    BASE_DIR + "/#{name.downcase.gsub(' ', '_')}_#{id}"
  end

  def serializable_hash(_options = {})
    { id: id,
      name: name,
      status: status,
      dependent_releases: dependent_releases }
  end

  def set_default_status
    open!
    true
  end

  def validate_status(status)
    enums = Release.statuses.map(&:first)
    raise PutitExceptions::EnumError, "Invalid status: #{status}, valids are: \"#{enums}\"" unless enums.include? status
  end
end
