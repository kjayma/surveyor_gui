module DependencyHelper
  def link_to_remove_tbody (name, f)
    f.hidden_field(:_destroy) + link_to_function(image_tag("delete.png",:border => 0, :margin=>'-1em'), "remove_tbody(this)")
  end
end
