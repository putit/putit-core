class DBSetting < ActiveRecord::Base
  self.table_name = 'settings'

  serialize :value, JSON
end
