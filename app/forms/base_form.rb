# TODO: Gem name idea "santana" – Santana::Form
class BaseForm
  class << self
    attr_reader :fields

    delegate :param_key, to: :model_name

    # TODO: Should be possible to fill more than one model
    def model(klass = nil)
      return @model if klass.nil?
      @model = klass
    end

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

  delegate :fields, :param_key, to: :class
  delegate :persisted?, :to_param, to: :model

  def initialize(model = self.class.model.new)
    @model = model
    @output_buffer = nil
    assign_attributes(model.attributes.slice(*fields.map { |field| field.name.to_s }))
  end

  def update(params)
    assign_attributes(clean_params(params))
    return false unless valid?
    model.update(clean_params(params))

    true
  end

  def to_html(form)
    elements = errors_html +
               fields.map { |field| field.to_html(form) } +
               [actions(form)]

    array_to_safe_buffer(elements)
  end

  # TODO: Move to partial
  def errors_html
    if errors.any?
      [content_tag(:div, class: "error_explanation") do
        content_tag(:h2, "Errors prohibited this item from being saved") +
          content_tag(:ul) do
            array_to_safe_buffer(errors.full_messages.map { |message| content_tag(:li, message) })
          end
      end]
    else
      []
    end
  end

  # TODO: Move to partial
  def actions(form)
    content_tag(:div, class: "actions") do
      form.submit
    end
  end

  def to_model
    self
  end

  private

  # TODO: Can be removed when everything is moved to partials
  include ActionView::Helpers::TagHelper
  attr_accessor :output_buffer

  def clean_params(params)
    fields.each_with_object({}) do |field, result|
      result[field.name] = field.transform(params[param_key])
    end
  end

  def array_to_safe_buffer(arr)
    arr.each_with_object(ActiveSupport::SafeBuffer.new) do |element, buffer|
      buffer << element
    end
  end
end

class FormField
  attr_reader :name

  def initialize(name, validations)
    @name = name
    @output_buffer = nil
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

  include ActionView::Helpers::TagHelper
  attr_accessor :output_buffer
  attr_reader :options
end

class TextField < FormField
end

class TextArea < FormField
end
