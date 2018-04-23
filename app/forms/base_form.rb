# TODO: Forms should also do validations
class BaseForm
  class << self
    attr_reader :fields

    def model(klass = nil)
      return @model if klass.nil?
      @model = klass
    end

    def field(name, type, options = {})
      @fields ||= []
      field_class = type.to_s.camelize.constantize
      delegate name, to: :model
      @fields.push(field_class.new(name, options))
    end

    def form_name
      model.name.underscore.to_sym
    end
  end

  attr_reader :model

  delegate :fields, :form_name, to: :class
  delegate :persisted?, to: :model
  alias to_model model

  def initialize(model = self.class.model.new)
    @model = model
    @output_buffer = nil
  end

  def update(params)
    @model.update(clean_params(params))
  end

  def to_html(form)
    # TODO: Display errors
    elements = fields.map { |field| field.to_html(form) } +
               [actions(form)]

    elements.each_with_object(ActiveSupport::SafeBuffer.new) do |element, buffer|
      buffer << element
    end
  end

  # Can be overwritten in child class
  def actions(form)
    content_tag(:div, class: "actions") do
      form.submit
    end
  end

  private

  include ActiveModel::Model
  include ActionView::Helpers::TagHelper
  attr_accessor :output_buffer

  def clean_params(params)
    field_names = fields.map(&:to_param)
    params.require(form_name).permit(*field_names)
  end
end

class FormField
  def initialize(name, options)
    @name = name
    @output_buffer = nil
    @options = options
  end

  def to_param
    name
  end

  private

  include ActionView::Helpers::TagHelper
  attr_accessor :output_buffer
  attr_reader :name
  attr_reader :options
end

# TODO: What is a simple way to adjust these fields to for example adhere to Bootstrap?
class TextField < FormField
  def to_html(form)
    content_tag(:div, class: "field") do
      form.label(name) + form.text_field(name, options)
    end
  end
end

class TextArea < FormField
  def to_html(form)
    content_tag(:div, class: "field") do
      form.label(name) + form.text_area(name, options)
    end
  end
end
