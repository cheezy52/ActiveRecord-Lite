require_relative 'db_connection'
require_relative '01_mass_object'
require 'active_support/inflector'

class MassObject
  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end
end

class SQLObject < MassObject
  def self.columns
    @cols ||= begin
      cols = DBConnection.execute2("SELECT * FROM #{table_name}").first
      cols.each do |col|
        define_method("#{col}") do
          attributes[col.to_sym]
        end
        define_method("#{col}=") do |arg|
          attributes[col.to_sym] = arg
        end
      end
      cols.map(&:to_sym)
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.name.underscore.pluralize
  end

  def self.all
    query = <<-SQL
    SELECT
      #{table_name}.*
    FROM
      #{table_name}
    SQL
    hashes = DBConnection.execute(query)
    parse_all(hashes)
  end

  def self.find(id)
    query = <<-SQL
    SELECT
      #{table_name}.*
    FROM
      #{table_name}
    WHERE
      id = #{id}
    SQL
    returned_obj = self.new(DBConnection.execute(query))
  end

  def attributes
    @attributes ||= {}
  end

  def insert
    col_names = attributes.keys.join(", ")
    question_marks = []
    attributes.length.times { question_marks << "?" }
    question_marks = question_marks.join(", ")

    query = <<-SQL
    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{question_marks})
    SQL
    DBConnection.execute(query, *attribute_values)
    self.id = DBConnection.last_insert_row_id
  end

  def initialize(params = nil)
    cols = self.class.columns

    params = params.first if params.is_a?(Array)
    if params.is_a?(Hash)
      params.each do |attr_name, val|
        raise "unknown attribute" unless cols.include?(attr_name.to_sym)
        attributes[attr_name.to_sym] = val
      end
    end
  end

  def save
    self.id.nil? ? self.insert : self.update
  end

  def update
    set_line = attributes.keys.map { |attr_name| "#{attr_name} = ?"}.join(", ")

    query = <<-SQL
    UPDATE
      #{self.class.table_name}
    SET
      #{set_line}
    WHERE
      id = #{self.id}
    SQL

    DBConnection.execute(query, *attribute_values)
  end

  def attribute_values
    attributes.keys.map { |key| attributes[key] }
  end
end
