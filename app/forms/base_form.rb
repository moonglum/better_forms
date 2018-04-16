class BaseForm
  class << self
    attr_reader :fields

    def model(klass = nil)
      return @model if klass.nil?
      @model = klass
    end

    def field(name, type)
      @fields ||= []
      @fields.push(Field.new(name, type))
    end

    def form_name
      model.name.underscore.to_sym
    end

    def find(id)
      new(model.find(id))
    end
  end

  attr_reader :model

  delegate :fields, :form_name, to: :class
  delegate :errors, to: :model
  alias to_model model

  def initialize(model = self.class.model.new)
    @model = model
  end

  def update(params)
    @model.update(clean_params(params))
  end

  private

  def clean_params(params)
    field_names = fields.map(&:name)
    params.require(form_name).permit(*field_names)
  end

  Field = Struct.new(:name, :type)
end
