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
    col_query = <<-SQL
    SELECT *
    FROM #{self.table_name}
    SQL

    cols = DBConnection.execute2(col_query).first
    cols.each do |col|
      define_method(col) do
        self.attributes[col]
      end

      define_method("#{col}=") do |val|
        self.attributes[col] = val
      end
    end

    cols.map(&:to_sym)
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.underscore.pluralize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
    SELECT #{self.table_name}.*
    FROM #{self.table_name}
    SQL

    self.parse_all(results)
  end

  def self.find(id)

    result = DBConnection.execute(<<-SQL, id)
    SELECT #{self.table_name}.*
    FROM #{self.table_name}
    WHERE #{self.table_name}.id = ?
    SQL

    self.new(result.first)
  end

  def attributes
    @attributes ||= {}
  end

  def insert
    col_vals = self.class.columns.map(&:to_s).join(", ")
    q_marks = (["?"] * self.class.columns.count).join(", ")
    insert_sql = <<-SQL
    INSERT INTO #{self.class.table_name} (#{col_vals})
    VALUES (#{q_marks})
    SQL

    insertion = DBConnection.execute(insert_sql, attribute_values)

    self.id = DBConnection.last_insert_row_id
  end

  def initialize( params = {} )
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      if self.class.columns.include?(attr_name)
        self.send("#{attr_name}=", value)
      else
        raise "unknown attribute '#{attr_name}'"
      end
    end
  end

  def save
    if id.nil?
      insert
    else
      update
    end
  end

  def update
    set_line = self.class.columns.map { |col| "#{col} = ?"}.join(", ")

    update_sql = <<-SQL
    UPDATE #{self.class.table_name}
    SET #{set_line}
    WHERE id = ?
    SQL

    DBConnection.execute(update_sql, attribute_values, self.id)
  end

  def attribute_values
    self.class.columns.map { |attribute| self.send(attribute)}
  end
end