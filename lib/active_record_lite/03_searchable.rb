require_relative 'db_connection'
require_relative '02_sql_object'

module Searchable
  def where(params)
    where_line = params.keys.map { |attr_name| "#{attr_name} = ?"}.join(" AND ")

    query = <<-SQL
    SELECT
      *
    FROM
      #{table_name}
    WHERE
      #{where_line}
    SQL

    parse_all(DBConnection.execute(query, *params.values))
  end
end

class SQLObject
  extend Searchable
end
