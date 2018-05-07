# TODO: Gem name idea "santana" – Santana::Form
class BaseForm
  class << self
    attr_reader :fields

    def method_missing(method_name, *args)
      if respond_to_missing?(method_name)
        add_field(method_name, *args)
      else
        super
      end
    end

    def respond_to_missing?(field_type, _include_all = nil)
      FormField.key?(field_type)
    end

    # This is basically the name of the resource
    # We remove the Form from that name
    def model_name
      ActiveModel::Name.new(self, nil, name.gsub(/Form\z/, ""))
    end

    def i18n_scope
      :form
    end

    private

    def add_field(field_type, name, validates: {}, html_options: {})
      field_class = FormField.fetch(field_type)

      attribute name, field_class.type
      validates name, validates unless validates.empty?

      @fields ||= []
      @fields.push(field_class.new(name, validates, html_options))
    end
  end

  include ActiveModel::Model
  include ActiveModel::Attributes

  # Initialize the form, optionally providing a parameter for the form
  #
  # If you form is called FooForm, then the form will post to foo_path
  # If you provide a param, it will post to foo_path(param)
  def initialize(param: nil)
    super()
    @param = param
  end

  # Prefill your form with a hash
  #
  # This is useful for update forms. It will ignore all attributes it doesn't know.
  def prefill_with(hash)
    assign_attributes(hash.slice(*attributes.keys))
  end

  # Apply parameters to your target object or objects
  #
  # This will first clean the parameters and check their validity
  # It will then call the update method, see below
  def apply(params, to:)
    clean_params = params.require(self.class.model_name.param_key).permit(*attributes.keys)
    assign_attributes(clean_params)
    return false unless valid?
    # TODO: If this returns false, we need to provide errors
    # Can we just overwrite errors to delegate to the object
    # if there are no errors?
    update(to, attributes)
  end

  # Update the target object or objects
  #
  # In the default case, it will just call update on the target
  # This can be overwritten if you want to update more than just one model
  def update(target, params)
    target.update(params)
  end

  # Render the form (this is called by the render_form helper)
  #
  # You need to provide the name of the view you want to use as
  # the layout for your form
  def render(form, layout:)
    ApplicationController.new.render_to_string(
      "forms/#{layout}",
      locals: {
        errors: errors,
        model_name: self.class.model_name,
        form: form,
        fields: self.class.fields
      },
      layout: false
    )
  end

  # This is necessary for form_with
  # This is unfortunately named. It basically asks if the param should be used or not
  def persisted?
    @param.present?
  end

  # This is necessary for form_with
  def to_param
    @param
  end
end

# TODO: Figure out how to do compound fields
class FormField
  class << self
    delegate :fetch, :key?, to: :@children

    def inherited(klass)
      @children[klass.name.underscore.to_sym] = klass
    end

    def type(assignment = nil)
      if assignment
        @type = assignment
      else
        @type || ActiveModel::Type::Value.new
      end
    end
  end

  @children = {}

  attr_reader :name

  def initialize(name, validations, html_options)
    @name = name
    @validations = validations
    @html_options = html_options
  end

  def options
    @html_options.merge(validations_to_attributes(@validations))
  end

  def to_partial_path
    "forms/#{self.class.name.underscore}"
  end

  private

  # TODO: Add missing validations:
  # acceptance, confirmation, exclusion, format, inclusion, length, numericality, absence
  def validations_to_attributes(validations)
    options = {}
    options[:required] = true if validations[:presence]
    options
  end
end

class TextField < FormField
  type :string
end

class TextArea < FormField
  type :string
end

class NumberField < FormField
  type :integer
end
