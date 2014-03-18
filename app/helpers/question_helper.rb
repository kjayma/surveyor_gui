module QuestionHelper
  def link_to_remove_fields (name, f)
    f.hidden_field(:_destroy) + link_to_function(image_tag("delete.png",:border => 0, :margin=>'-1em'), "remove_fields(this)")
  end

  def link_to_add_fields(name, id, f, association, formclass="f", table=false, div=false, dirpath=nil)
    fkey=':'+ f.object_name.underscore+'_id'
    setid = "{"+fkey+"=>"+id.to_s+"}"

    if id
      new_object = eval(f.object_name).reflect_on_association(association).klass.new(eval(setid))
    else
      new_object = eval(f.object_name).reflect_on_association(association).klass.new
    end

    if eval(f.object_name).reflect_on_association(association).klass.accessible_attributes.include?('display_order')
      new_object.display_order = eval(f.object_name).reflect_on_association(association).klass.maximum(:display_order)+1
    end
    new_object.class.reflect_on_all_autosave_associations.each do |ar|
      #build a query string that checks if f.object has an existing child object. This should be due to an
      #accepts_nested_attributes_for relationship, causing autosave. If the child does not exist, we'll create one.
      query_string = 'new_object.'+ar.name.to_s
      #if child does not exist and only for belongs_to relationships
      if !eval(query_string) && ar.macro == :belongs_to
        build_string = 'new_object.build_'+ar.name.to_s
        #build a new empty child record
        eval(build_string)
      end
    end

    fields = f.simple_fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(dirpath.to_s+association.to_s.singularize + "_fields", formclass.to_sym => builder)
    end
    if table
      if div
        #organized the grouping originally by tr. Had to do it by div for survey logic, so added this.
        link_to_function(image_tag("addicon.png",:border => 0), "add_fields3(this, \"#{association}\", \"#{escape_javascript(fields)}\")")
      else
        link_to_function(image_tag("addicon.png",:border => 0), "add_fields3(this, \"#{association}\", \"#{escape_javascript(fields)}\")")
      end
    else
      link_to_function(image_tag("addicon.png",:border => 0), "add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")")
    end
  end
end
