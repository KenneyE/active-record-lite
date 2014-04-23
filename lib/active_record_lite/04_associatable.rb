require_relative '03_searchable'
require 'active_support/inflector'

# Phase IVa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    self.class_name.constantize
  end

  def table_name
    if class_name == "Human"
      return @table_name = "humans"
    end
    @table_name = self.class_name.underscore.pluralize
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @class_name = options[:class_name]
    @foreign_key = options[:foreign_key]
    @primary_key = options[:primary_key]

    @class_name ||= name.to_s.camelcase.singularize
    @foreign_key ||= "#{name}_id".to_sym
    @primary_key ||= :id
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})

    @class_name = options[:class_name]
    @foreign_key = options[:foreign_key]
    @primary_key = options[:primary_key]

    @class_name ||= name.to_s.camelcase.singularize
    @foreign_key ||= "#{self_class_name.underscore}_id".to_sym
    @primary_key ||= :id
  end
end

module Associatable
  # Phase IVb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)

    define_method(name) do
      fkey = send(options.foreign_key)
      options.model_class.where(id: fkey).first
    end
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.name, options)
    define_method(name) do
      id = send(options.primary_key)
      options.model_class.where(options.foreign_key => id)
    end
  end

  def assoc_options
    # Wait to implement this in Phase V. Modify `belongs_to`, too.
  end
end

class SQLObject
  # Mixin Associatable here...
  extend Associatable
end
