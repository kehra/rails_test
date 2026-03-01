class Demo::LegacyTaskProjection < ApplicationRecord
  self.table_name = "tasks"
  self.ignored_columns = [ "description" ]
end
