require_relative 'db_connection'
require_relative '02_sql_object'

module Searchable
  def where(params)
    conditions = params.keys
    values = params.values

    where_line = conditions.map {|cond| "#{cond.to_s} = ?"}.join(" AND ")

    where_sql = <<-SQL
    SELECT *
    FROM #{self.table_name}
    WHERE #{where_line}
    SQL

    results = DBConnection.execute(where_sql, values)
    parse_all(results)
  end
end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end
