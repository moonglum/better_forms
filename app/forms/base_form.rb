# TODO: Gem name idea "santana" – Santana::Form
class BaseForm
  class << self
    attr_reader :fields

    def field(name, type, options = {})
      @fields ||= []
      field_class = type.to_s.camelize.constantize
      attr_accessor name

      validations = parse_options(options)
      validates name, validations unless validations.empty?

      @fields.push(field_class.new(name, validations))
    end

    def model_name
      ActiveModel::Name.new(self, nil, name.gsub(/Form\z/, ""))
    end

    private

    # TODO: Add missing validations
    def parse_options(options)
      validations = {}
      validations[:presence] = true if options[:presence]
      validations
    end
  end

  include ActiveModel::AttributeAssignment
  include ActiveModel::Validations

  attr_reader :model

  delegate :fields, to: :class
  delegate :persisted?, :to_param, to: :model

  # TODO: How can we fill more than one model?
  def initialize(model)
    @model = model
    assign_attributes(model.attributes.slice(*fields.map { |field| field.name.to_s }))
  end

  def update(params)
    assign_attributes(clean_params(params))
    return false unless valid?
    model.update(clean_params(params))

    true
  end

  def to_html(form)
    merge_safe_buffers(
      errors_html,
      *fields.map { |field| field.to_html(form) },
      actions_html(form)
    )
  end

  def to_model
    self
  end

  private

  def clean_params(params)
    fields.each_with_object({}) do |field, result|
      result[field.name] = field.transform(params[self.class.model_name.param_key])
    end
  end

  def errors_html
    ApplicationController.new.render_to_string(
      partial: "fields/errors",
      locals: { errors: errors, model_name: self.class.model_name }
    )
  end

  def actions_html(form)
    ApplicationController.new.render_to_string(
      partial: "fields/actions",
      locals: { form: form }
    )
  end

  def merge_safe_buffers(*safe_buffers)
    safe_buffers.each_with_object(ActiveSupport::SafeBuffer.new) do |safe_buffer, result|
      result << safe_buffer
    end
  end
end

class FormField
  attr_reader :name
  attr_reader :options

  def initialize(name, validations)
    @name = name
    @options = validations_to_attributes(validations)
  end

  # Can be overwritten by child class for transforming to different type
  # or to collect multiple fields into one value
  def transform(params)
    params[name]
  end

  def to_html(form)
    ApplicationController.new.render_to_string(
      partial: "fields/#{self.class.name.underscore}",
      locals: { form: form, name: name, options: options }
    )
  end

  private

  def validations_to_attributes(validations)
    options = {}
    options[:required] = true if validations[:presence]
    options
  end
end

class TextField < FormField
end

class TextArea < FormField
end
