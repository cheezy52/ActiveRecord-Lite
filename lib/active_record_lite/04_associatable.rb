require_relative '03_searchable'
require 'active_support/inflector'

# Phase IVa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key,
  )

  ActiveSupport::Inflector.inflections do |inflect|
     inflect.irregular 'human', 'humans'
  end

  def model_class
    class_name.constantize
  end

  def table_name
    class_name.underscore.pluralize
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = options[:foreign_key] ? options[:foreign_key] : "#{name}_id".to_sym
    @primary_key = options[:primary_key] ? options[:primary_key] : "id".to_sym
    @class_name = options[:class_name] ? options[:class_name] : "#{name.to_s.camelcase.singularize}"
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = options[:foreign_key] ? options[:foreign_key] : "#{self_class_name.underscore}_id".to_sym
    @primary_key = options[:primary_key] ? options[:primary_key] : "id".to_sym
    @class_name = options[:class_name] ? options[:class_name] : "#{name.to_s.camelcase.singularize}"
  end
end

module Associatable
  # Phase IVb
  def belongs_to(name, opts = {})
    options = BelongsToOptions.new(name, opts)
    define_method(name) do
      fk = options.send(:foreign_key)
      model_class = options.send(:model_class)
      obj = model_class.where("id" => self.send(fk)).first
    end
    assoc_options[name] = options
  end

  def has_many(name, opts = {})
    options = HasManyOptions.new(name, self.name, opts)

    define_method(name) do
      fk = options.send(:foreign_key)
      model_class = options.send(:model_class)
      objs = model_class.where(fk.to_s => self.id)
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
