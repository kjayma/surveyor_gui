( function($) {
    $(document).ready(function() {
      application_js_code();
    });

 } ) ( jQuery );

function application_js_code(){

// jquery_trigger_ready.js
// this function is added to jQuery, it allows access to the readylist
// it works for jQuery 1.3.2, it might break on future versions
//      if (!Modernizr.input.required) {
  $('[required="required"]').addClass('required');
  $.validator.addMethod('require-check',
      function (value,element) {
        return $(element).closest('ol').find('.require-check:checked').size() > 0;
      },
      'Please check at least one box.'
  );
  $.validator.addMethod('uislider',
      function (value,element) {
        return $(element).val() != null;
      },
      'Please make a choice.'
  );
  $('form').each(function(){
    $(this).validate({
        ignore:':not(input[class*="star-rating-applied"], select[class*="uislider"]):hidden',
      groups: getGroups(),
      errorPlacement: function(error, element) {
        if (element.attr("type") === "checkbox"  )
          error.insertAfter($(element).closest('ol').find('li').last());
        else if(element.attr("type") === "radio") {
          if (element.is('.star-rating-applied'))
            error.insertAfter($(element).closest('ol'));
          else
            error.insertAfter($(element).closest('ol').find('li').last());
        }
        else if (element.is('.uislider'))
            error.insertAfter($(element).closest('ol'));
        else
          error.insertAfter(element);
      }
    });
  });

  $.blockUI.defaults.css = {
    padding:        0,
    margin:         0,
    width:          '100px',
    top:            '40%',
    left:           '35%',
    textAlign:      'center',
    color:          '#000',
    border:         'none',
    backgroundColor:'#fff',
    cursor:         'wait'
  };

  $(document).bind('cbox_open', function(){
     if($(parent.$.find('input#pass_cbox_data')).length>0) {
       $(parent.$.find('input#pass_cbox_data')).val('false');
     }
  });
  $(document).on("click", "#survey_section_submit, #question_submit, #dependency_submit", function(event) {
      //pass_cbox_data is a div at the top of /views/surveyforms/_form.html.erb
      $(parent.$.find('input#pass_cbox_data')).val('true');
  });
  $(document).on('ajaxComplete', 'form.question, form.survey_section, form.dependency, form.edit_survey_section', function(event) {
      if ($("#errorExplanation").length===0){
        if($(parent.$.find('input#pass_cbox_data')).length>0) {
          if($(parent.$.find('input#pass_cbox_data')).val()==='true'){
            parent.$.fn.colorbox.close();
          }
        }
      }
      else {
        $(parent.$.find('input#pass_cbox_data')).val('false');
      }
  });

  $(window).load(function() {
      if ($("#errorExplanation").length===0){
        if($(parent.$.find('input#pass_cbox_data')).length>0) {
          if($(parent.$.find('input#pass_cbox_data')).val()==='true'){
            parent.$.fn.colorbox.close();
          }
        }
      }
      else {
        $(parent.$.find('input#pass_cbox_data')).val('false');
      }
      var isInIFrame = (window.location != window.parent.location) ? true : false;
      if(isInIFrame) {
        $('body').css({background:'#f3f3f3'});
      }
  });


  $(document).on('click', '#edit_section_title', function() {
    var edit_survey_section_url = $(this).data('edit_survey_section_url');
    var replace_survey_section_url = $(this).data('replace_survey_section_url');
    var survey_section_id = $(this).data('survey_section_id');
    $.colorbox({
      width:"40%",
      height:"30%",
      scrolling:true,
      iframe:true,
      onClosed:function(){
        submitted = $("input#pass_cbox_data").val();
        if (submitted) {
          $.get(replace_survey_section_url,
            {},
            function(response) {
              $("#survey_section_"+survey_section_id).html(replace_idx($("#survey_section_"+survey_section_id),"survey_sections", response));
              refresh_stars();
            }
          );
        };
      },
      href: edit_survey_section_url,
      opacity:.3
    });
  });

  $(document).on('click', '#delete_section', function() {
    var survey_section_url = $(this).data('survey_section_url');
    var survey_section_id = $(this).data('survey_section_id');
    $.ajax({
      type: "DELETE",
      url: survey_section_url,
      success: function(msg){
        if (typeof msg !== undefined  && msg.length>0) {
          alert(msg);
        }
        else {
          $("#survey_section_"+survey_section_id).remove();
            update_question_numbers();
            update_dependency_questions();
        }
      }
    });
  });

  $('.sortable_sections').sortable({
    axis:"y",
    opacity: 0.6,
    scroll: true,
    update: function(){
      $.ajax({
        type: 'post',
        data: $('.sortable_sections').sortable('serialize')+'&survey_id='+$('input#surveyform_id')[0].value,
        dataType: 'script',
        complete: function(request){
        $('#survey_section').effect('highlight');
      },
      url: '/survey_sections/sort'})
    }
  });

  $('.sortable_questions').sortable({
    axis:"y",
    opacity: 0.6,
    scroll: true,
    connectWith: ".sortable_questions",
    update: function(){
      $.ajax({
        type: 'post',
        data: getAllSerialize()+'&survey_id='+$('input#surveyform_id')[0].value,
        dataType: 'script',
        complete: function(request){
        $('#survey_section').effect('highlight');
        update_question_numbers();
      },
      url: '/questions/sort'})
    }
  });

  $.fn.sortable_answers = function(){
    $('#sortable_answers').sortable({
      axis:"y",
      opacity: 0.6,
      scroll: true,
      update: function(){
        $.ajax({
          type: 'post',
          handle: '.answer_handle',
          data: $('#sortable_answers').sortable('serialize')+'&question_id='+$('input#question_id')[0].value,
          dataType: 'script',
          complete: function(request){
            $('#sortable_answers').effect('highlight');
            parent.cbox.data('submitted','true');
        },
        url: '/answers/sort'})
      }
    });
  };


  update_uislider();

  $("input.date_picker").datepicker({ duration: 'fast',  showOn: 'both', buttonImage: '../../assets/datepicker.gif', buttonImageOnly: true });

  $.fn.check_dynamic_source = function (){
    if ($(this).closest('#answer_choice').find('input[id^="question_dynamically_generate_true"]').prop('checked')) {
      $(this).closest('div#answer_choice').find('div#dynamic_source').show();
      $(this).closest('div#answer_choice').find('div#fixed_source').hide();
//      $('#question_answers_attributes_0_text').val('String');
    }
    else{
      $(this).closest('div#answer_choice').find('div#dynamic_source').hide();
      $(this).closest('div#answer_choice').find('div#fixed_source').show();
    }
  };

  $.fn.render_picks_partial = function (){
    here = $(this)
    $.get(
      "/questions/" + $(this).closest('.questions').find('input#question_id').val() + "/render_picks_partial" ,
      function(data){
        here.html(data);
        here.check_dynamic_source();
        here.sortable_answers();
      }
    );
  }

  $.fn.render_no_picks_partial = function (){
    here = $(this)
    $.get(
      "/questions/" + $(this).closest('.questions').find('input#question_id').val() + "/render_no_picks_partial" ,
      function(data){
        here.html(data);
      }
    );
  }

  $.fn.show_answers = function (){
    if ($(this).val() in {'Multiple Choice (only one answer)':1,'Multiple Choice (multiple answers)':1,'Slider':1}){
      $('#question_answers_attributes_0_text').val($('#original_choice').data('original_choice'));
      $('#answer_choice').render_picks_partial();
      if ($('input[id^="question_dynamically_generate"]:checked').val() in {'t':1,'true':1}){
        $('#fixed_source').hide();
        $('#dynamic_source').show();
      }
    }
    else
    {
      $('#answer_choice').html('');
      switch($(this).val)
      {
      case 'Number':
        $('#question_answers_attributes_0_text').val('Float');
        break;
      case 'Text':
        $('#question_answers_attributes_0_text').val('Text');
        break;
      default:
        $('#question_answers_attributes_0_text').val('String');
      }
    }
  };

  $.fn.show_number_questions = function (){
    if ($(this).val() === "Number"){
      $('#number_questions').render_no_picks_partial();
    }
    else
    {
      $('#number_questions').html('');
    }
  };

/*
  $.fn.update_widgets = function(){
    $(this).find('select.uislider').each(function() {
      $(this).selectToUISlider({
        labels:2,
        labelSrc: "text",
        sliderOptions: {
          stop: function(e, ui) { // handle stop sliding event
            $(this).parents('form').trigger('slider_change');
          }
        }
      }).hide();
    });
    $(this).find("input.date_picker").datepicker(
      { duration: 'fast',  showOn: 'both', buttonImage: '../../assets/datepicker.gif', buttonImageOnly: true }
    );
  }
*/
  $('input[id^="question_question_type_"]').on('change', function(event){
    $(this).show_answers();
    $(this).show_number_questions();
  });
  $('input:checked[id^="question_question_type_"]').show_number_questions();
  $('input:checked[id^="question_question_type_"]').show_answers();
  $('input[id$="rule_key_temp"]').on('updateInputs', update_logic);
  $('select[id$="join_operator"]').first().parents('tr').hide();
  $('select[id$="join_operator"]').on('change', update_logic);

  $('.report_data_display').hide();

  //when modifying dependency logic, change the answers based on the question selected
  //and change the answer field from a pulldown to an entry field, depending on the question type
  $('select[id^="question_dependency_attributes_dependency_conditions_attributes"][id$="question_id"]').each( function() {
    $.get('/dependencys/get_question_type',
        'question_id='+$(this).val(),
        function(data){
          data = data.split(',');
          var pick = data[0];
          var response_class = data[1];
          var display_type = data[2];
          if (pick==='none') {
            $('#dependency_pick_multiple_choice').hide();
            $('#dependency_float').show();
            $('#dependency_star').hide();
          }
          else if (display_type==='stars'){
            $('#dependency_pick_multiple_choice').hide();
            $('#dependency_float').hide();
            $('#dependency_star').show();
          }
          else{
            $('#dependency_pick_multiple_choice').show();
            $('#dependency_float').hide();
            $('#dependency_star').hide();
          }
        }
      );
  });
  $('select[id^="question_dependency_attributes_dependency_conditions_attributes"][id$="question_id"]').on('change',function(event) {
    $('[id^="question_dependency_attributes_dependency_conditions_attributes"][id$="answer_id"]')
      .load(
        '/dependencys/get_answers',
        'question_id='+$(this).val()
      );
    $.get('/dependencys/get_question_type',
        'question_id='+$(this).val(),
        function(data){
          data = data.split(',');
          var pick = data[0];
          var response_class = data[1];
          var display_type = data[2];
          if (pick==='none') {
            $('#dependency_pick_multiple_choice').hide();
            $('#dependency_float').show();
            $('#dependency_star').hide();
          }
          else if (display_type==='stars'){
            $('#dependency_pick_multiple_choice').hide();
            $('#dependency_float').hide();
            $('#dependency_star').show();
          }
          else{
            $('#dependency_pick_multiple_choice').show();
            $('#dependency_float').hide();
            $('#dependency_star').hide();
          }
        }
      );

    //<%= c.hidden_field :answer_id, :value => Answer.where('question_id=?',c.object.question_id).first.id %>
    //<%= c.input :float_value %>

  });



  $('input.autocomplete').each(function(){
    update_autocomplete_idx(this);
  });

  $("form[id^='survey_form']").find('.filename_with_link').find('a').each(function(){
    var filenamediv = $(this).parent('.filename_with_link');
    //regexp filter finds the input with the correct response id field, e.g. r_4, and extracts the id
    var response_id = $(this).closest('ol').find('input').filter(function() {
      return /r_\d+_id/.test( $(this).attr('id'));
    }).val();
    insert_file_delete_icon(filenamediv,response_id);
  });


  //when uploading a file, modify the view current name and link
  //with new version of jquery, the jquery-ujs iframe call is coming back with an error on json results.  Does not seem to affect surveyor.js
  //and cannot figure out how to get the result to return without error.
  //Seems to be interpreted by jquery as an xml result even though its json, and the <textarea> tag seems to throw off the parser.
  $('form').bind("ajax:success, ajax:error", function(){
    if ( $(this).data('remotipartSubmitted') ){
      var object_names=$(this).find('input[type="file"]');
      //if the upload is associated with a survey question, retrieve the response, extract filename, and display it, with a link to view file.
      object_names.each(function(){
        var object_name=$(this).attr('data-object-class');
        var object_id = $(this).attr('id');
        indexRegExp1 = /[0-9]+/g;
        var idx  = parseInt(indexRegExp1.exec(object_id));
        indexRegExp1.lastIndex = 0;
        if (object_name=='Response') {
          var response_set_id=$(this).closest('ol').find('input[type="file"]').attr('data-response_set_id');
          var question_id = $(this).closest('ol').find('input[type="file"]').closest('ol').find('input[id$="question_id"]').val();
          $.get('/surveyor/get_response_id?question_id='+question_id+"&response_set_id="+response_set_id, function(data){
            var response_id = data
            if (response_id) {
              //now get the the name of the file, so we can display the name of the file and a link to the user.
              $.get('/pages/get_filename?object='+object_name+'&id='+response_id, function(data){
                //we'll stuff the link into the div called filename_with_link
                var filenamediv = $('input[id$="question_id"][value="'+question_id+'"]').closest('ol').find('.filename_with_link');
                filenamediv.html('current file is: ' + data );
                //add a delete icon
                insert_file_delete_icon(filenamediv,response_id,idx);

                //insert the response.id so we don't do insert when update needed
                insert_id_if_missing(filenamediv.closest('ol').find('input'), response_id);

                //now insert the response id inputs for star and slider fields, which also would be handled by jquery.surveyor.js, but were bypassed.
                //nested associations will force an insert of these fields, and the response ids are necessary to avoid duplicate inserts in further
                //further operations
                selects = $("form[id^='survey_form'] select").add("form[id^='survey_form'] li.star");
                selects.each(function(){
                  var question_id = $(this).closest('ol').find('input[id$="question_id"]').val();
                  var context = this
                  $.get('/surveyor/get_response_id?question_id='+question_id+"&response_set_id="+response_set_id, function(data2){
                    insert_id_if_missing($(context).closest('ol').find('input'), data2);
                  });
                });
                //ajax done, unblock
                $('input, select, submit').unblock();
              });
            }
          });
        }
      });
    }
  });
}

  function getAllSerialize() {
    $('.sortable_questions').each(function(index, value) {
      if (index === 0) {
        newarr = $(this).sortable('serialize',{key:$(this).attr('id')+'[]'});
      }
      else{
        newarr = newarr+'&'+$(this).sortable('serialize',{key:$(this).attr('id')+'[]'});
      }
    });
    return newarr;
  }

  function insert_id_if_missing(wrapped_set, response_id){
    //get the id of the form element
    var first_id = wrapped_set[0].id;
    indexRegExp1 = /[0-9]+/g;
    //extract the index
    idx  = parseInt(indexRegExp1.exec(first_id));
    //determine if the r_<idx>_id input field exists.
    var id_input_exists = wrapped_set.filter(function() {
      return /r_\d+_id/.test( $(this).attr('id'));
    }).length;
    //if the input field does not exist, create it, to avoid inserting a duplicate response through the nested attributes processing
    //this would normally be handled by the successfulSave method of jquery.surveyor.js, but gets bypassed by remotipart in
    //order to process the file upload.
    if (!id_input_exists) {
       wrapped_set.filter('input[id$="question_id"]').after('<input id="r_'+idx+'_id" class="" type="hidden" value="'+response_id+'" name="r['+idx+'][id]">');
    };
    indexRegExp1.lastIndex = 0;
  }

  function insert_file_delete_icon(filenamediv, response_id, idx){
    //retrieve the link to the delete icon
    if (filenamediv.find('img').length==0  && response_id) {
      var img = filenamediv.attr('data-image-path');
      //create the link
      var js = "remove_attachment('Response',"+response_id+","+idx+"); return false;";
      var newclick = new Function(js);
      filenamediv.append('<img src="'+img+'" />').find('img').attr('onclick', '').click(newclick);
    }
  }

  function CurrencyFormatted(amount) {
	  var i = parseFloat(amount);
	  if(isNaN(i)) { i = 0.00; }
	  var minus = '';
	  if(i < 0) { minus = '-'; }
	  i = Math.abs(i);
	  i = parseInt((i + .005) * 100);
	  i = i / 100;
	  s = new String(i);
	  if(s.indexOf('.') < 0) { s += '.00'; }
	  if(s.indexOf('.') == (s.length - 2)) { s += '0'; }
	  s = minus + s;
	  return s;
  }

  function copy_fieldset(link) {
    var last_fieldset = link.closest('fieldset').filter(':last').find('input, select').filter(':first');
    var idx = get_1st_index(link.closest('form').find('fieldset').filter(':last').find('tr.fields input').filter(':first'));
    idx = idx+1;
    var new_fieldset = link.closest('form').find('fieldset').filter(':last').clone();
    new_fieldset.find('input, select').each(function(){
      var old_id = this.id;
      //replace first occurrence of a number (dont want to change anything but the lowest nested attribute)
      var new_id = old_id.replace(/\d/,idx);
      this.id = new_id;$('#sortable_answers')
      var old_name = this.name;
      var new_name = old_name.replace(/\d/,idx);
      this.name = new_name;
      $(this).removeAttr('value');
      this.disabled = null;
    });
    last_fieldset.closest('fieldset').after(new_fieldset)
    new_fieldset.before('<br />');
    new_fieldset.focus();
    return new_fieldset;
  }
  function copy_row(link_source,destination) {
    var last_tr = link_source.closest('fieldset').find('tr.fields').filter(':last').find('input, select').filter(':first');
    var fsindex = get_1st_index(link_source.closest('fieldset').find('tr.fields input').filter(':first'));
    var idx = get_index(last_tr);
    idx = idx+1;
    var new_tr = link_source.closest('fieldset').find('tr.fields').filter(':last').clone();
    new_tr.find('input, select').each(function(){
      var old_id = this.id;
      //replace last occurrence of a number (dont want to change anything but the lowest nested attribute)
      var new_id = old_id.replace(/\d(?!.*\d)/g,idx);
      new_id = new_id.replace(/\d+(?=_fs_products_attributes)/g,fsindex);
      this.id = new_id;
      var old_name = this.name;
      var new_name = old_name.replace(/\d(?!.*\d)/g,idx);
      new_name = new_name.replace(/\d+(?=_fs_products_attributes)/g,fsindex);
      this.name = new_name;
      $(this).removeAttr('value');
      this.disabled = null;
    });
    $(destination).closest('tr').before(new_tr);
    return new_tr;
  }

  function update_logic() {
      var rule_keys = $('input[id$="rule_key_temp"]');
      if (rule_keys.length > 1) {
        //if is not a number
        var last_key = rule_keys[rule_keys.length-2].value;
        if (isNaN(last_key)){
          var new_key = 0;
        }
        else {
          var new_key = parseInt(last_key)+1;
        }
      }
      else
      {
        new_key = 0;
      }
      rule_keys.last().val(new_key);
      var rule = '';
      rule_keys.each(function(index) {
        if (index===0) {
          rule = $(this).val();
        }
        else {
          rule = rule +' '+$(this).parents('tbody').find('tr').first().find('select').val()+' '+ $(this).val()+' ';
        }
      });
      $('input[id$="rule"]').val(rule);
  }


  function update_display_order(link) {
    $(link).each(function(index, value){
      $(value).find('input[id$="display_order"]').first().val(index+1);
    });
  }

  function get_index(link) {
    var object_id = link.attr('name');
    var indexRegExp1 = /\d+(?!.*\d)/g;
    var idx  = parseInt(indexRegExp1.exec(object_id));
    indexRegExp1.lastIndex = 0;
    return idx;
  }


  function get_1st_index(link) {
    //ugly hack.  replace later with a more generalized function that pulls the nth index
    var object_id = link.attr('name');
    var indexRegExp1 = /\d+/;
    var idx  = parseInt(indexRegExp1.exec(object_id));
    indexRegExp1.lastIndex = 0;
    return idx;
  }


  function replace_idx(link, association, content) {
      var indexRegExp1 = new RegExp("[0-9]+");
      var idx  = $(link).length+1;
      indexRegExp1.lastIndex = 0;
      var regexp = new RegExp(association+"_attributes_0", "g");
      var content = content.replace(regexp, association+"_attributes_"+idx);
      regexp = new RegExp(association+"_attributes\]\\[0", "g");
      content = content.replace(regexp, association+"_attributes]["+idx);
      return content;
  }


  function update_question_numbers() {
    $('span.questions').each(function(index, value){
      var regexp =  /\d+\)/g;
      $(value).html($(value).html().replace(regexp, (index+1)+')'));
      $(value).prev('input[id$="display_order"]').val(index+1);
    });
  }

  function update_dependency_questions(wizard_step) {
    $('.question_logic_notifier').closest('div.question').each(function(){
      var id = $(this).closest('div.question').attr('id').match(/\d+/)[0]
      $.get("/surveyforms/0/replace_question?question_id="+id+"&wizard_step="+wizard_step,
        {},
        function(response) {
          $("#question_"+id).html(replace_idx($("#question_"+id),"questions", response));
          //update_question_numbers();
          $.unblockUI();
        }
      );
    });
  }

  function refresh_stars(link) {
    if (link === undefined){
	    $('input[type=radio].star').rating();
    }
    else {
      $(link).find('input[type=radio].star').rating();
    }

  }

  function open_or_close_the_description_of_other(select_box) {
      if (select_box.val()==='other') {
        select_box.closest('td').next('td').find('div').attr('style',false).show();
      };
      if (select_box.val()!='other') {
        select_box.closest('td').next('td').find('div').attr('style',false).hide();
      };
  }
  function remove_fields(link) {
      $(link).prev("input[type=hidden]").val("1");
      $(link).closest(".fields").hide();
  }

  function remove_tbody(link) {
      $(link).prev("input[type=hidden]").val("1");
      $(link).closest("tbody").hide();
  }


  function remove_fieldset(link) {
      $(link).prev("input[type=hidden]").val("1");
      $(link).closest('fieldset').filter(':first').hide();
      $(link).closest('.add_financial_scenario_button').hide();
  }

  function remove_relation(link, url) {
      var return_value =
          $.ajax( {
            type: "GET",
            url: url,
            async: false
            }
          ).responseText;
      if (return_value === "success"){
        $(link).closest('tr').remove();
      }
      else {
        $(link).closest('tr').remove();
      }
  }

  function add_fields(link, association, content) {
      var new_id = new Date().getTime();
      var regexp = new RegExp("new_" + association, "g");
      a=$(link).parent().before(content.replace(regexp, new_id)).prev().find('input[type!="hidden"]').first().focus();
//      alert($(link).parent().prev().find('select').last().attr('id'));
  }


  function update_autocomplete_idx(link) {
    elements = $(link).attr('data-update-elements');
    if (elements) {
      var regexp = new RegExp("autocompleteidx", "g");
      var id = $(link).attr('id');
      indexRegExp1 = /[0-9]+/g;
      idx  = parseInt(indexRegExp1.exec(id));
      indexRegExp1.lastIndex = 0;
      elements = elements.replace(regexp,idx);
      $(link).attr('data-update-elements',elements);
    }
  }

  function remove_attachment(object,id,idx) {
    //remove the carrierwave attachment, return the mandatory attribute
    $.get('/pages/remove_attachment?object='+object+'&id='+id, function(data){
      //clear the div containing the old name and delete icon
      $('.filename_with_link').html('');

      //clear the filename from the form.  Unlike other fields, HTML prohibits us from directly altering the value in a file field.
      //instead, we need to remove the current <input type='file'> and replace it with a freshly inserted input field.
      var file_input = $('input[id="r_'+idx+'_id"]').nextAll('li').find('input[type="file"]');
      var par=file_input.parent();
      var fi = $('<input>',{
        id: file_input.attr('id'),
        name: file_input.attr('name'),
        type: 'file'
      });
      fi.attr('data-response_set_id',file_input.attr('data-response_set_id'));
      fi.attr('data-object-id',file_input.attr('data-object-id'));
      fi.attr('data-object-class', file_input.attr('data-object-class'));
      //data returns true if mandatory field or nil
      if (data && data==="true") {
        fi.attr("required","required");
      }
      par.html(fi);

      //since the response object is gone, need to remove the r_id to, or the controller will think
      //this question has a response.  That would let a blank field pass even if mandatory, and,
      //since this is in a nested form, would get the controller to try an update when the object of the update no longer exists.
      $('input[id="r_'+idx+'_id"]').remove();
    });
  }

  function go_back() {
    $('#initial_buttons').show();
    $('#deny_buttons').hide();
    $('#revise_buttons').hide();
    $('#show_schedule').show();
    $('#revise_schedule').hide();
  }
  function go_back_2() {
    $('#revision_requests').show();
    $('#revision_form').hide();
    $('#withdrawal_form').hide();
    $('#make_revisions_button').show();
  }
  function show_survey_report_data() {
    $('.report_data').show();
    $('.show_survey_report_data_button').hide();
  }
  function hide_survey_report_data() {
    $('.report_data').hide();
    $('.show_survey_report_data_button').show();
  }

  function getGroups() {
    var result = {};
    var checkbox_names = {};
    var ols = $('input[type="checkbox"], input[type="radio"]').closest('ol');
    ols.each(function(i) {
      var checkbox_names = $.map(
        $(this).find('input[type="checkbox"]'),
        function(e,i) {
          return $(e).attr("name");
        }
      ).join(" ");
      result['fieldPair_' + i] = checkbox_names;
    });
    return result;
  }

  function update_uislider(){
    $('select.uislider').each(function() {
      if(typeof $(this).selectToUISlider == 'function') {
        $(this).selectToUISlider({
          labels:2,
          labelSrc: "text",
          sliderOptions: {
            stop: function(e, ui) { // handle stop sliding event
              $(this).parents('form').trigger('slider_change');
            }
          }
        }).hide();
      }
    });
  }

  function modal_dialog(title, dialog_content,yes_callback,no_callback){
/*      var modal_response="";
      $('.modal_button').live('click',function(){
        $.colorbox.close();
        modal_response = $(this).text();
      });
     $.colorbox({
        html: dialog_content,
        width:"400px",
        height:"250px",
        fixed: true,
        scrolling:false,
        onLoad: function() {
          $('#cboxClose').remove();
        },
        onClosed:function(){
          if (modal_response==="No") {
            no_callback();
          }
          else {
            yes_callback();
          }
        },
        opacity:.3
      });
*/
    $('<div></div>').appendTo('body')
      .html(dialog_content)
      .dialog({
        closeOnEscape: false,
        modal: true,
        title: title,
        zIndex: 10000,
        autoOpen: false,
        fixed: true,
        width: 'auto',
        resizable: false,
        buttons: {
            Yes: function() {
              $(this).dialog("close");
              yes_callback ();
            },
            No: function() {
              $(this).dialog("close");
              no_callback ();
            }
        },
        open: function(event, ui) {
          $(".ui-dialog-titlebar-close").hide();
        },
        close: function (event, ui) {
            $(this).remove();
        }
      }).parent().css({position:"fixed"}).end().dialog('open');
  }
