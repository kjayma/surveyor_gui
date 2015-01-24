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
  surveyor_gui_mount_point = $("#surveyor-gui-mount-point").data("surveyor-gui-mount-point");
  if (surveyor_gui_mount_point.length==0){
    surveyor_gui_mount_point="/";
  } else {
    surveyor_gui_mount_point= surveyor_gui_mount_point.replace(/surveyforms/i, ""); 
  }

  $.ajaxSetup({
    headers: {
      'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
    }
  });

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
  $(document).on("click", "#survey_section_submit, #question_submit, #question_group_submit, #dependency_submit", function(event) {
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
    var edit_survey_section_url =     $(this).data('edit_survey_section_url');
    var replace_survey_section_url =  $(this).data('replace_survey_section_url');
    var survey_section_id =           $(this).data('survey_section_id');
    $.colorbox({
      width:"40%",
      height:"30%",
      scrolling:false,
      iframe:true,
      onClosed:function(){
        submitted = $("input#pass_cbox_data").val();
        if (submitted) {
          $.get(replace_survey_section_url,
            {},
            function(response){
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
    var survey_section_url =  $(this).data('survey_section_url');
    var survey_section_id =   $(this).data('survey_section_id');
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


  $(document).on('click', '#add_question', function() {
    var insert_new_question_url = $(this).data('insert_new_question_url');
    var new_question_url =        $(this).data('new_question_url');
    var survey_section_id =       $(this).parents("div.survey_section").find("input[id$=\'id\']").first().val()
    var prev_question_id =        $(this).data('prev_question_id');
    var question_id =             null;
    //provides a way to check that this function is complete in tests.  It disappears on complete when
    //the contents of div#box are replaced.
    $('div#box').addClass('jquery_add_question_started');
    $.colorbox({
      width:"850px",
      height:"772px",
      scrolling:true,
      iframe:true,
      onCleanup:function(){
          $("#cboxLoadedContent iframe").load(function(){
              question_id = $("iframe.cboxIframe").contents().find("#cboxQuestionId").html();
          });
      },
      onClosed:function(){
          submitted = $("input#pass_cbox_data").val();
          if (submitted==="true") {
              $.get(insert_new_question_url+"?question_id="+question_id,
              {},
              function(response) {
                replace_surveyform_contents(response);
              }
            );
          }
      },
      href: new_question_url+'?survey_section_id='+survey_section_id+(prev_question_id ? '&prev_question_id='+prev_question_id : ''),
      opacity:.3}
    );
  });

  $(document).on('click', '#add_section', function() {
    var insert_survey_section_url = $(this).data('insert_survey_section_url');
    var new_survey_section_url =    $(this).data('new_survey_section_url');
    var survey_section_id =         $(this).data('survey_section_id');
    var survey_id =                 $(this).data('survey_id');
    //provides a way to check that this function is complete in tests.  It disappears on complete when
    //the contents of div#box are replaced.
    $('div#box').addClass('jquery_add_section_started');
    $.colorbox({width:"517px;",
      height:"167px;",
      scrolling:false,
      iframe:true,
      onClosed:function(){
          submitted = $("input#pass_cbox_data").val();
          if (submitted) {
              $.get(insert_survey_section_url,
                {},
                function(response) {
                  $("#survey_section_"+survey_section_id).after(replace_idx($(".survey_section"),"survey_sections", response));
                  $('div#box').removeClass('jquery_add_section_started');
                }
              );
          }
       },
      href: new_survey_section_url+'?prev_section_id='+survey_section_id+'&suppress_header=true&survey_id='+survey_id,
      opacity:.3
    });
  });

  $(document).on('click', '#edit_question', function() {
    var replace_question_url =  $(this).data('replace_question_url');
    var edit_question_url =     $(this).data('edit_question_url');
    var survey_section_id =     $(this).closest('.survey_section').find('input#surveyform_survey_sections_attributes_0_id').val();
    var question_id =           $(this).data('question_id');
    $.colorbox({
      width:"850px",
      height:"772px",
      scrolling:true,
      iframe:true,
      onClosed:function(){
        submitted = $("input#pass_cbox_data").val();
        if (submitted) {
          $.get(replace_question_url,
            {},
            function(response) {
              if (response=="not found"){
                $.get("/surveyforms/"+survey_section_id+"/replace_survey_section?survey_section_id="+survey_section_id,
                  {},
                  function(response){
                    $("#survey_section_"+survey_section_id).html(replace_idx($("#survey_section_"+survey_section_id),"survey_sections", response));
                    refresh_stars();
                  }
                );                           
              } 
              else {
                $("#question_"+question_id).html(replace_idx($("#question_"+question_id),"questions", response));
                refresh_stars();
                $("#question_"+question_id).update_single_uislider();
                update_question_numbers();              
              }
            }
          );
        };
      },
      href: edit_question_url,
      opacity:.3
    });
  });

  $(document).on('click', '#cut_section', function() {
    var cut_section_surveyform_url = $(this).data('cut_section_surveyform_url');
    var section_already_cut =        $(this).data('section_already_cut');
    //provides a way to check that this function is complete in tests.  It disappears on complete when
    //the contents of div#box are replaced.
    $('div#box').addClass('jquery_cut_section_started');
    $.get(cut_section_surveyform_url,
      {},
      function(response) {
        replace_surveyform_contents(response);
      }
    );
  });

  $(document).on('click', '#paste_section', function() {
    var paste_section_surveyform_url = $(this).data('paste_section_surveyform_url');
    //provides a way to check that this function is complete in tests.  It disappears on complete when
    //the contents of div#box are replaced.
    $('div#box').addClass('jquery_paste_section_started');
    $.get(paste_section_surveyform_url,
      {},
      function(response) {
        replace_surveyform_contents(response);
      }
    );
  });

  $(document).on('click', '#cut_question', function() {
    var cut_question_surveyform_url = $(this).data('cut_question_surveyform_url');
    var question_already_cut =        $(this).data('question_already_cut');
    //provides a way to check that this function is complete in tests.  It disappears on complete when
    //the contents of div#box are replaced.
    $('div#box').addClass('jquery_cut_question_started');
    $.get(cut_question_surveyform_url,
      {},
      function(response) {
        replace_surveyform_contents(response);
      }
    );
  });

  $(document).on('click', '#paste_question', function() {
    var paste_question_surveyform_url = $(this).data('paste_question_surveyform_url');
    //provides a way to check that this function is complete in tests.  It disappears on complete when
    //the contents of div#box are replaced.
    $('div#box').addClass('jquery_paste_question_started');
    $.get(paste_question_surveyform_url,
      {},
      function(response) {
        replace_surveyform_contents(response);
      }
    );
  });

  $(document).on('click', '#delete_question', function() {
    var question_url =                $(this).data('question_url');
    var replace_form_surveyform_url = $(this).data('replace_form_surveyform_url');
    $.ajax({
      type: "DELETE",
      url: question_url,
      success: function(msg){
        if (typeof msg !== undefined && msg.length>0) {
          alert(msg);
          }
        else {
          $.get(replace_form_surveyform_url,
            {},
            function(response) {
              replace_surveyform_contents(response);
            }
          );
        }
      },
      error: function(){
        alert("This question cannot be deleted.");
      }
    });
  });

  $(document).on('click', '#edit_logic', function() {
    var replace_question_url =  $(this).data('replace_question_url');
    var edit_dependency_url =   $(this).data('edit_dependency_url');
    var question_id =           $(this).data('question_id');
    $.colorbox({
      width:"98%",
      height:"80%",
      scrolling:true,
      iframe:true,
      onClosed:function(){
        submitted = $("input#pass_cbox_data").val();
        if (submitted) {

          $.get(replace_question_url,
            {},
            function(response) {
              var question=$("#question_"+question_id).html(replace_idx($("#question_"+question_id),"questions", response));
              refresh_stars(question);
              update_question_numbers();
            }
          );
        };
      },
      href: edit_dependency_url,
      opacity:.3
    });
  });

  $(document).on('click', '#delete_logic', function() {
    var replace_question_url =  $(this).data('replace_question_url');
    var dependency_url =  $(this).data('dependency_url');
    var question_id =           $(this).data('question_id');
    $.ajax({
      type: "DELETE",
      url: dependency_url,
      success: function(msg){
        $.get(replace_question_url,
          {},
          function(response) {
            var question=$("#question_"+question_id).html(replace_idx($("#question_"+question_id),"questions", response));
            refresh_stars(question);
            update_question_numbers();
            }
          );
        },
        error: function(){
        alert("This logic cannot be deleted.");
      }
    });
  });

  $(document).on('click', '#add_logic', function() {
    var replace_question_url =  $(this).data('replace_question_url');
    var new_dependency_url =    $(this).data('new_dependency_url');
    var question_id =           $(this).data('question_id');
    $.colorbox({
      width:"98%",
      height:"50%",
      scrolling:true,
      iframe:true,
      onClosed:function(){
        submitted = $("input#pass_cbox_data").val();
        if (submitted) {
          $.get(
            replace_question_url,
            {},
            function(response) {
              var question=$("#question_"+question_id).html(replace_idx($("#question_"+question_id),"questions", response));
              refresh_stars(question);
              update_question_numbers();
            }
          );
        };
      },
      href: new_dependency_url,
      opacity:.3
    });
  });

  $(document).on('click', '.go_back', function() {
    history.back();
  });

  sortable_sections_and_questions();

  $.fn.sortable_answers = function(){
    $('#sortable_answers').sortable({
      axis:"y",
      opacity: 0.6,
      scroll: true,
      update: function(){
        update_answer_display_order();
      }
    });
  };


  update_uislider();
  update_datepickers();

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

  $.fn.render_no_picks_partial = function (){
    var render_no_picks_partial_url = $('#no_picks_partial_url').data("render_no_picks_partial_url");
    here = $(this)
    $.get(
      render_no_picks_partial_url + "?id="+ $(this).closest('.questions').find('input#question_id').val(),
      function(data){
        here.html(data);
      }
    );
  }

  $.fn.render_answer_fields_partial = function (add_row){
    here = $(this);
    var answer_fields_partial_url = $("#answer_fields_partial_url").data("answer_fields_partial_url");
    if (add_row === true) {
      var option = "&add_row=true";
    }
    else {
      option = ' ';
    }
    $.get(
      answer_fields_partial_url + "?id=" + $(this).closest('.questions').find('input#question_id').val() + option,
      function(data){
        if (add_row == true) {
          data = replace_idx($(".question_answers_text"),"answers", data)
          here.append(data);
        }
        else {
          here.html(data);
        }
        here.check_dynamic_source();
        here.sortable_answers();
      }
    );
  }

  $.fn.render_grid_fields_partial = function (question_type, index){
    here = $(this);
    var render_grid_partial_url = $("#render_grid_partial_url").data("render_grid_partial_url");
    index = typeof index !== 'undefined' ? index : null;
    $.get(
      render_grid_partial_url + "?id="
        + $(this).closest('.questions').find('input#question_id').val()
        + "&question_type_id="+question_type
        + "&index=" + parseInt(index)
        ,
      function(data){
        here.html(data);
        here.check_dynamic_source();
        here.sortable_answers();
        update_uislider();
        check_dropdown_column_count();
      }
    );
  }

  function render_question (){
    var here = $('body');
    var survey_section_id = $('input[id$="survey_section_id"]').val();
    var text = $('textarea[id*="question"][id$="_text"]').val();
    var display_order = $('input[id$="display_order"]').last().val();
    var question_id = $('.questions').find('input#question_group_question_id').val()
    var question_type_id = $('div.question_type input[id*="question_type_id"]:checked').val();
    if (question_id != undefined && question_id != "")  {
      var question_clause = "/"+question_id+"/edit";
    }
    else
      var question_clause = "/new";
    window.location.href = surveyor_gui_mount_point+"questions"+question_clause +"?survey_section_id="+
        survey_section_id+"&text="+text+
        "&display_order="+display_order +
        "&question_type_id="+question_type_id;
  }
  
  function render_question_group (){
    var here = $('body');
    //var original_question_id = $('input[id="question_id"]')
    var survey_section_id = $('input[id$="survey_section_id"]').val();
    var text = $('textarea[id*="question"][id$="_text"]').val();
    var display_order = $('input[id$="display_order"]').last().val();
    var question_id = $('input#question_id').val();
    var question_group_id = $('.questions').find('input[id*="question_group_id"]').val();
    var question_type_id = $('div.question_type input[id*="question_type_id"]:checked').val();
    if (question_group_id != undefined && question_group_id != "")  {
      var question_group_clause = "/"+question_group_id+"/edit";
    }
    else
      var question_group_clause = "/new";

      window.location.href = surveyor_gui_mount_point+"question_groups"+question_group_clause+"?survey_section_id="+
        survey_section_id+"&text="+text+
        "&display_order="+display_order +
        "&question_id="+question_id +
        "&question_type_id="+question_type_id;

  }

  $.fn.render_group_inline_fields_partial = function (add_row){
    here = $(this);
    var render_group_inline_partial_url = $("#render_group_inline_partial_url").data("render_group_inline_partial_url");
    var survey_section_id = $('input#question_group_survey_section_id').val();
    if (add_row === true) {
      var option = "&add_row=true";
    }
    else {
      option = ' ';
    }
    var last_question = $(this).closest('.questions').find('input#question_group_id').first();
    var display_order = (this).closest('.questions').find('input[id$="display_order"]').last().val();
    display_order = parseInt(display_order) + 1;
    $.get(
      render_group_inline_partial_url + "?id="
        + last_question.val() + 
        "&display_order=" + display_order + 
        option,
      function(data){
        if (add_row == true) {
          data = replace_idx($(".group_inline_question"),"questions", data)
          $('.sortable_group_questions').last().after(data);
        }
        else {
          $('#answer_choice').html(data);
        }
        $('.group_inline_question').last().show_group_answers();
        $('.group_inline_question').each(function(){
          $('input[id$="survey_section_id"]').val(survey_section_id);
        });
        update_group_answers();
        sortable_sections_and_questions();
      }
    );
  }

  //$.fn.render_grid_dropdown_columns = function (i){
  //  here = $(this);
  //  $.get(
  //    "/question/render_grid_dropdown_columns?id="
  //      + $(this).closest('.questions').find('input#question_id').val()+
  //      "&index=" + parseInt(i) + "&question_type_id='grid_dropdown'",
  //    function(data){
  //      here.append(data);
  //      here.check_dynamic_source();
  //      here.sortable_answers();
  //      update_uislider();
  //    }
  //  );
  //}

  $('#answer_choice').on('click', '.add_answer img', function () {
    $('#sortable_answers').render_answer_fields_partial(true);
  });


  $('#answer_choice').on('click','.add_group_inline_question', function() {
    $(this).render_group_inline_fields_partial(true);
  });

  $.fn.show_answers = function (){
    if ($(this).val()
        in {
        'pick_one':1,
        'pick_any':1,
        'slider':1,
        'dropdown':1}){
      $('#question_answers_attributes_0_text').val($('#original_choice').data('original_choice'));
      $('#answer_choice').show();
      $(this).check_dynamic_source();
      $(document).on('click','input[id^="question_dynamically_generate"]', function() {
        $(this).check_dynamic_source();
      });
      $('#sortable_answers').render_answer_fields_partial();
      if ($('input[id^="question_dynamically_generate"]:checked').val() in {'t':1,'true':1}){
        $('#fixed_source').hide();
        $('#dynamic_source').show();
      }
    }
    else if ($(this).val() in {'grid_one':1, 'grid_any':1, 'grid_dropdown':1}){
      $('#question_answers_attributes_0_text').val($('#original_choice').data('original_choice'));
      $('#sortable_answers').render_grid_fields_partial((this).val());
      $('#answer_choice').show();
    }
    else if ($(this).val() in {"group_inline":1, "group_default":1, "repeater":1}){
      $('#question_answers_attributes_0_text').val($('#original_choice').data('original_choice'));
      //$('#sortable_answers').render_group_inline_fields_partial((this).val());
      render_question_group();
    }
    else
    {
      $('#answer_choice').hide();
      $('#sortable_answers').html('');
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

  $.fn.show_group_answers = function () {
    if ($(this).val()
      in {
      'pick_one':1,
      'pick_any':1,
      'slider':1,
      'dropdown':1})
      $(this).closest('.group_inline_question').find('.group_answers_textbox').show();
    else
      $(this).closest('.group_inline_question').find('.group_answers_textbox').hide();
  }

  $.fn.show_number_questions = function (){
    if ($(this).val() === "number"){
      $('#number_questions').render_no_picks_partial();
    }
    else
    {
      $('#number_questions').html('');
    }
  };

  function update_group_answers(){  
    $('.group_inline_question').on('change', 'select[id^="question_group_questions_attributes_"]', function(){
      $(this).show_group_answers();
    });
  }

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
  $('input[id^="question_question_type_"],input[id^="question_group_question_type_"]').on('change', function(event){
    if (!($(this).val() in {"group_inline":1,"group_default":1,"repeater":1}) && $('.edit_question_group, .new_question_group').length > 0){
      render_question();
    }
    else {
      $(this).show_answers();
      $(this).show_number_questions();
    }
  });

  $('.group_inline_question').each( function(){
    $(this).find('select[id$="question_type_id"]').show_group_answers();
  });
  $('.group_inline_question').on('change', 'select[id^="question_group_questions_attributes_"]', function(){
    $(this).show_group_answers();
  });



  $('input[id^="question_question_type_"]:checked').each(function(event){
    $(this).show_number_questions();
    $(this).show_answers();
  });

  $('input#dependency_submit').on('click').trigger('submit');

  $('.surveyor_gui_report .report_data_display').hide();

  $.fn.render_dependency_conditions_partial = function (add_row){
    if ($(this).length > 0) {
      here = $(this);
      if (add_row === true) {
        var option = "&add_row=true";
      }
      else {
        option = ' ';
      }
      $.get(
        surveyor_gui_mount_point+"dependency/render_dependency_conditions_partial?id=" + $(this).data('question_id') + 
        "&dependency_id=" + $(this).data('dependency_id') + option,
        function(data){
          if (add_row === true) {
            data = replace_idx($(".question_dependency_dependency_conditions_question_id"),"dependency_conditions", data)
            here.append(data);
          }
          else {
            here.html(data);
          }
          $('select[id*="dependency_conditions_attributes"][id$="question_id"]').each( function() {
            $(this).determine_dependency_question_type();
          });
          $('select[id$="join_operator"]').first().parents('tr').hide();
        }
      );
    }
  }

  $('#dependency_conditions_partial').render_dependency_conditions_partial();

  $('div.dependency_editor').on('click', '.add_condition img', function () {
    $(this).closest('div').find('#dependency_conditions_partial').render_dependency_conditions_partial(true);
  });


  //when modifying dependency logic, change the answers based on the question selected
  //and change the answer field from a pulldown to an entry field, depending on the question type
//  $('select[id^="question_dependency_attributes_dependency_conditions_attributes"][id$="question_id"]').each( function() {
//    $(this).determine_dependency_question_type();
//  });
  $('.dependency_editor').on('change', 'select[id*="dependency_conditions_attributes"][id$="question_id"]', function(event) {
    $(event.target).determine_dependency_question_type();
  });
  $('.dependency_editor').on('change', 'select[id*="dependency_conditions_attributes"][id$="column_id"]', function(event) {
    $(event.target).refresh_dependency_answers();
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

  $('.surveyor_gui_report .show_data').on('click', function(){ show_survey_report_data(); });
  $('.surveyor_gui_report .hide_data').on('click', function(){ hide_survey_report_data(); });


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

  function replace_surveyform_contents(response) {
    $("div#box").filter(":last").replaceWith(response);
    sortable_sections_and_questions();
    refresh_stars();
    update_uislider();
    update_datepickers();
  }

  function check_dropdown_column_count() {
    $('select[id="question_dropdown_column_count"]').on('change', function(event){
      count = $(this).val()
//      for (var i = 0; i < count; i++) {
//        var grid_dropdown_columns = $(this).closest('div').nextAll('.grid_dropdown_columns');
//        grid_dropdown_columns.html("");
        $(this).closest('#sortable_answers').render_grid_fields_partial('grid_dropdown', count);
//      };
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
    //span.questions gets the text for the question, e.g. "1) what is your name?"
    $('span.questions').each(function(index, value){
      var regexp =  /\d+\)/g;
      $(value).html($(value).html().replace(regexp, (index+1)+')'));
      //display order is a hidden field placed just before span.questions in the DOM
      $(value).prev('input[id$="display_order"]').val(index+1);
    });
  }


  function update_answer_display_order () {
    $('#sortable_answers').find('input[id$="display_order"]').each(function(index, value){
      $(value).val(index);
    });
  }

  function update_dependency_questions() {
    $('.question_logic_notifier').closest('div.question').each(function(){
      var id = $(this).closest('div.question').attr('id').match(/\d+/)[0]
      $.get(surveyor_gui_mount_point+"surveyforms/0/replace_question?question_id="+id,
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


  function sortable_sections_and_questions() {
    var survey_locked = $('.sortable_sections').data('survey_locked');

    if (!survey_locked) {
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
          url: surveyor_gui_mount_point+'survey_sections/sort'})
        }
      });
      

      $('.sortable_group_questions').sortable({
        axis:"y",
        opacity: 0.6,
        scroll: true,
        connectWith: ".sortable_group_questions",
        update: function(){
          var questions = $('.group_inline_question')
          var display_order = Math.min.apply(
            null,
            questions.find(
              'input[id*="display_order"]'
            ).map(
              function(){
                return parseInt($(this).val());
              }
            ).toArray()
          );
          $('.group_inline_question').each(function(index, value){ 
            questions.eq(index).find('input[id*="display_order"]').val(display_order+index);
          });
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
            data: getAllSerialize()+'&survey_id='+$('input[id*="surveyform_id"]')[0].value,
            dataType: 'script',
            complete: function(request){
              $('#survey_section').effect('highlight');
              update_question_numbers();
            },
            url: surveyor_gui_mount_point+'/questions/sort'
          })
        }
      });
    }
  }


  function show_dependency_value(data, target) {
    target = target.closest('tr').find('td.answer_field');
    data = data.split(',');
    var pick = data[0];
    var question_type = data[1];
    var question_id   = data[2];
    target.find('.dependency_pick_multiple_choice').hide();
    target.find('.dependency_float').hide();
    target.find('.dependency_star').hide();
    target.find('.dependency_number').hide();
    target.find('.dependency_text_box').hide();
    target.find('.dependency_date').hide();
    target.find('.dependency_text').hide();
    target.closest('tr .column_id').hide();
    if (/(one|any)/.test(question_type)) {
      target.find('.dependency_pick_multiple_choice').show();
    }
    else if (question_type=="dropdown") {
      target.find('.dependency_pick_multiple_choice').show();
    }
    else if (question_type=="grid_dropdown") {
      target.find('.dependency_pick_multiple_choice').show();
      target.refresh_dependency_columns(question_type, question_id);
    }
    else if (question_type=="stars"){
      target.find('.dependency_star').show();
    }
    else if (question_type=='number'){
      target.find('.dependency_float').show();
    }
    else if (question_type=='box'){
      target.find('.dependency_text_box').show();
    }
    else if (question_type=='date'){
      target.find('.dependency_date').show();
    }
    else {
      target.find('.dependency_text').show();
    }
    target.refresh_dependency_answers();
  }

  function remove_fields(link, dom_to_hide) {
      dom_to_hide = dom_to_hide || ".fields";
      $(link).prev("input[type=hidden]").val("1");
      $(link).closest(dom_to_hide).hide();
  }

  function remove_dependency_condition(link) {
      $(link).prev("input[type=hidden]").val("1");
      $(link).closest("tr").hide().prev("tr").hide();
  }


  function remove_fieldset(link) {
      $(link).prev("input[type=hidden]").val("1");
      $(link).closest('fieldset').filter(':first').hide();
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
    $('.non_repeater .report_data').show();
    $('.show_survey_report_data_button').hide();
  }
  function hide_survey_report_data() {
    $('.surveyor_gui_report .report_data').hide();
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

  $.fn.update_single_uislider = function(){
    var slider_element = $(this).find('select.uislider').first();
    if(slider_element.length>0 && typeof slider_element.selectToUISlider == 'function') {
      slider_element.selectToUISlider({
        labels:2,
        labelSrc: "text",
        sliderOptions: {
          stop: function(e, ui) { // handle stop sliding event
            slider_element.parents('form').trigger('slider_change');
          }
        }
      }).hide();
    }
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

  function update_datepickers(){
    $("input.date_picker")
      .datepicker({
        duration: 'fast',
        showOn: 'both',
        buttonImage: '/../../assets/datepicker.gif',
        buttonImageOnly: true
    });
    $("input.datetime_picker")
      .datetimepicker({
        duration: 'fast',
        showOn: 'both',
        buttonImage: '../../assets/datepicker.gif',
        buttonImageOnly: true
    });
    $("input.time_picker")
      .timepicker({
        duration: 'fast',
        showOn: 'both',
        buttonImage: '../../assets/datepicker.gif',
        buttonImageOnly: true
    });
  }

  $.fn.determine_dependency_question_type = function () {
    var target = $(this);
    $.get(surveyor_gui_mount_point+'dependencys/get_question_type',
      'question_id='+$(this).val(),
      function(data){
        show_dependency_value(data,target);
      }
    );
  }

  $.fn.refresh_dependency_answers = function() {
    var question_id =
      $(this).closest("tr").find('[id*="dependency_attributes_dependency_conditions_attributes"][id$="question_id"]').val();
    var column_id   =
      $(this).closest("tr").find('[id*="dependency_attributes_dependency_conditions_attributes"][id$="column_id"]').val();
    var dependency_condition_id =
      $(this).closest("tr").find('[id*="dependency_attributes_dependency_conditions_attributes"][id$="_id"]').val();
    $(this).closest('tr').find('[id*="dependency_attributes_dependency_conditions_attributes"][id$="answer_id"]')
      .load(
      surveyor_gui_mount_point+'dependencys/get_answers',
      'question_id='+question_id +
      '&dependency_condition_id='+dependency_condition_id +
      '&column_id='+column_id
    );
  }

  $.fn.refresh_dependency_columns = function(question_type, question_id) {
    var column = $(this).closest('tr').find('[id*="dependency_attributes_dependency_conditions_attributes"][id$="column_id"]');
    var dependency_condition_id =
      $(this).closest("tr").find('[id*="dependency_attributes_dependency_conditions_attributes"][id$="_id"]').val();
    column.closest('.column_id').show()
    $.get(
      surveyor_gui_mount_point+'dependencys/get_columns',
      'question_id='+question_id +
      '&dependency_condition_id='+dependency_condition_id,
      function(data){
        column.html(data);
        column.refresh_dependency_answers();
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
