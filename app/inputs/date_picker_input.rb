class DatePickerInput < SimpleForm::Inputs::Base
  def input
    @builder.text_field(attribute_name,input_html_options)
  end
end


