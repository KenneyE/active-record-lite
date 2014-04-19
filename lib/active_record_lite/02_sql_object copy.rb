require_relative 'db_connection'
require_relative '01_mass_object'
require 'active_support/inflector'

class MassObject
  def self.parse_all(results)
    res = results.map { |result| self.new(result) }
  end
end

class SQLObject < MassObject
  def self.columns

    col_query = <<-SQL
      SELECT *
      FROM #{self.table_name}
    SQL

    cols = DBConnection.execute2(col_query)[0]

    cols.each do |col|
      define_method(col) do
        instance_variable_get("@#{col}")
      end

      define_method("#{ col }=") do |val|
        instance_variable_set("@#{col}", val)
      end
    end
    cols.map! { |col| col.to_sym }
    cols
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    return @table_name unless @table_name.nil?
    @table_name = self.to_s.underscore.pluralize
  end

  def self.all
    all_query = <<-SQL
    SELECT #{self.table_name}.*
    FROM #{self.table_name}
    SQL

    all = DBConnection.execute(all_query)
    self.parse_all(all)
  end

  def self.find(id)
    find_query = <<-SQL
      SELECT #{table_name}.*
      FROM #{table_name}
      WHERE #{table_name}.id = ?
    SQL

    parse_all(DBConnection.execute(find_query, id)).first

  end

  def attributes
    @attributes ||= Hash.new
  end

  def insert
    puts "columns and question marks"
    p self.attributes
    col_names = self.class.columns.map(&:to_sym).join(", ")
    q_marks = (["?"] * self.class.columns.count).join(", ")

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
      #{self.class.table_name} (#{col_names})
      VALUES
      (#{q_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def initialize(params)
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      if self.class.columns.include?(attr_name)
        self.send("#{ attr_name }=", value )
      else
        raise "unknown attribute #{attr_name}"
      end
    end
  end

  def save
  end

  def update
    # find(self.id) = self
  end

  def attribute_values
    self.attributes.map { |attribute| self.send(attribute) }
  end
end
