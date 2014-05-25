module DependencyHelper
  def link_to_remove_tbody (name, f)
    f.hidden_field(:_destroy) + link_to(image_tag("delete.png",:border => 0, :margin=>'-1em'), "#", onclick: "remove_dependency_condition(this);")
  end
end
