( function($) {
    $(document).ready(function() {
      application_js_code();
      if ($('#surveyor').length > 0)
        all_surveyor_code();
      if ($.mobile) {
        $('div:jqmData(role="page")').live('pagebeforeshow',function(){
            application_js_code();
            if ($('#surveyor').length > 0)
              all_surveyor_code();
        });
      }

//  jQuery("input[type='file']").change(function(){
//      $(this).parents('form').trigger('submit');
//  });
    });
 } ) ( jQuery );

function application_js_code(){

      $("body").not(':has(div#surveyor)').on({
          ajaxStart: function() {
              $(this).addClass("loading");
          }
      });
      $("body").on({
          ajaxStop: function() {
              $(this).removeClass("loading");
          }
      });

      $('input[type="submit"]').click(function(){
         if ($(this).closest('form').valid())
          $('body').addClass("loading");
      });
      $('a[href!=""][href!="#"][href!="#.html"][href!="#undefined"][class!="no_spinner"]').click(function(){
         $('body').addClass("loading");
      });

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
//      };

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
      $("#survey_section_submit, #question_submit, #dependency_submit").bind('click', function(event) {
          //pass_cbox_data is a div at the top of /views/surveyforms/_form.html.erb
          $(parent.$.find('input#pass_cbox_data')).val('true');
      });
      $(document).on('click','input[type="submit"]', function(event) {
        if(window.parent.$('.cboxIframe').length>0){
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



/*
      $('document form[class="simple_form evaluation"]').find('select[id$="unit_of_measure"]').live('change', function(event){
        open_or_close_the_description_of_other($(this));
      });
      $('form[class="simple_form evaluation"]').find('select[id$="unit_of_measure"]').each(function(){open_or_close_the_description_of_other($(this));});
      $('form[class="simple_form evaluation"]').find('[id$="catalogue_number"]').bind('railsAutocomplete.select', function(){
        selectbox = $(this).closest('tr').find('select[id$="unit_of_measure"]');
        open_or_close_the_description_of_other(selectbox);
      });
      $(".num").regexMask(/^\d+$/);
      $('.evaluation_progress_bar, .timeline_link, .evaluation_timeline_task').bind('mouseenter', function(event) {
        var mycolor = $(this).css('backgroundColor');
        $(this).data('mycolor',mycolor);
        $(this).siblings('.timeline_link').each(function(){
            var MyElem = $(this);
            MyElem.data('mycolor',MyElem.css('backgroundColor'));
        });
        $(this).css('background-color','white');
        $(this).siblings('.timeline_link').css('background-color','white');
      });
      $('.evaluation_progress_bar, .timeline_link, .evaluation_timeline_task').bind('mouseout', function(event) {
        var mycolor = $(this).data('mycolor');
        $(this).css('background-color',mycolor);
        $(this).siblings('.timeline_link').each(function(){
          mycolor = $(this).data('mycolor');
          $(this).css('backgroundColor', mycolor);
        });
      });
      $('.evaluation_progress_bar, .timeline_link').bind('click', function(event) {
        var eid = $(this).closest('td').attr('eid');
        var isMobile = navigator.userAgent.match(/(iPhone|iPod|iPad|Android|BlackBerry)/);
        if (eid) {
          if (isMobile) {
            location.href = 'gantt_chart?evaluation_institution_id='+eid;
          }
          else {
            location.href = 'pages/gantt_chart?evaluation_institution_id='+eid;
          }
        }
      });
      $('.evaluation_timeline_task').bind('click', function(event){
        showOrHide = $(this).data('showOrHide');
        $('.events_and_milestones').toggle(showOrHide);
        $(this).data('showOrHide')=!showOrHide;
      });
//      $("ul.tabs").tabs("div.panes > div");
      $("ul.statustabs").tabs("div.statuspanes > div");
      //on the evaluation form, show the duration question if the vendor wants to specify an evaluation duration.
      $('input[id*="deadline_flag"]:checked').each(function(n){
        if ($(this).val()==="true"){
          $(this).closest('tr').next('tr[id="evaluation_proposed_duration"]').show();
        }
        else {
          $(this).closest('tr').next('tr[id="evaluation_proposed_duration"]').hide();
        }
      });

      $('input[id*="deadline_flag"]').live('click', function(event){
        if ($(event.target).val()=="true") {
          $(event.target).closest('tr').next('tr[id="evaluation_proposed_duration"]').show();
        }
        else
        {
          $(event.target).closest('tr').next('tr[id="evaluation_proposed_duration"]').hide();
        }
      });
      $('form[action="make_request_revisions"]').bind('submit',function(event){
        if ($(this).find('textarea[id="evaluation_institution_request_revision_response"]').val()===''){
          alert('Please describe the revisions you will agree to in the text box at the bottom of the page.');
          return false;
        }
      });
      $("ul.tabs").tabs("div.panes > div");
//      $("ul.statustabs").tabs("div.statuspanes > div");
      $("ul.wizardtabs").tabs("div.wizardpanes > div");

      $('form.question div#dynamic_source').hide();
      $('form.question div#fixed_source').each(function(event){
        if ($('input[id^="question_dynamically_generate"]:checked').val()==='true' || $('input[id^="question_dynamically_generate"]:checked').val()==='t'){
          $(event.target).closest('div#answer_choice').find('div#fixed_source').hide();
        }
      });
      $('input[id^="question_dynamically_generate"]').live('click', function(event){
        if ($(event.target).val()==='true') {
          $(event.target).closest('div#answer_choice').find('div#dynamic_source').show();
          $(event.target).closest('div#answer_choice').find('div#fixed_source').hide();
//          $('#question_answers_attributes_0_text').val('String');
        }
        else{
          $(event.target).closest('div#answer_choice').find('div#dynamic_source').hide();
          $(event.target).closest('div#answer_choice').find('div#fixed_source').show();
        }
      });



      update_uislider();

      $("input.date_picker").datepicker({ duration: 'fast',  showOn: 'both', buttonImage: '/images/datepicker.gif', buttonImageOnly: true });
      $('input:checked[id^="question_question_type_"]').show_answers();
      $('input[id^="question_question_type_"]').bind('change', function(event){
        $(this).show_answers();
        $(this).show_number_questions();
      });
      $('input:checked[id^="question_question_type_"]').show_number_questions();
      $('input[id$="rule_key_temp"]').live('updateInputs', update_logic);
      $('select[id$="join_operator"]').first().parents('tr').hide();
      $('select[id$="join_operator"]').live('change', update_logic);

      $('ul.sf-menu').superfish();
      $('.wizardtabs li').click(function(){
        current_step = parseInt($('input[id$="institution_wizard_step"]').val());
        link_step = $(this).attr('step');
        //only allow a user to jump backwards through the wizard, not forward)
        if (link_step < current_step) {
          location.href = $(this).attr('href');
        }
      });
      $('.wizardtabs li').each(function(index){
        step = parseInt($('input[id$="institution_wizard_step"]').val());
        if (index<step) {
          $(this).addClass("checkmark");
        }
        if (index===(step)) {
          $(this).addClass("current_tab");
        }
        if (index>=step) {
          $(this).removeClass("checkmark");
        }
        if (index>step) {
          $(this).removeClass("current_tab");
        }
      });

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
      $('select[id^="question_dependency_attributes_dependency_conditions_attributes"][id$="question_id"]').live('change',function(event) {
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

      //when creating or editing evaluations, and after selecting departments, list the evaluation leader for the department, and update the list of possible recipients
      //for the evaluation.
      $('#new_evaluation , form[id^="edit_evaluation"]').find('select[id$="department_id"]').each(function(){
        $(this).closest('td').find('.department_head').load('/evaluations/get_department_head', ('department_id='+$(this).val()));
        $(this).closest('fieldset').find('select[id$="evaluation_initiator"]')
         .load(
          '/evaluations/get_evaluation_initiator',
          $(this).closest('fieldset').find('select, input').serialize(),
          function(){
            $(this).attr('disabled',false);
          }
         )
      });
      $('#new_evaluation select[id$="department_id"], form[id^="edit_evaluation"] select[id$="department_id"]').live('change',function(event){
        $(event.target).closest('td').find('.department_head').load('/evaluations/get_department_head', ('department_id='+$(event.target).val()));
        $(event.target).closest('fieldset').find('select[id$="evaluation_initiator"]')
         .load(
          '/evaluations/get_evaluation_initiator',
          $(event.target).closest('fieldset').find('select, input').serialize(),
          function(){
            $(this).attr('disabled',false);
          }
         )
      });

      //when updating institutions, after entering a department and identifying its evaluation leader, list the evaluation leader's name next to his or her email.
      $('input[id$="user_email"]').live('railsAutocomplete.select', function(event, data){
        $(this).closest('tr').find('.fullname').load('/institutions/get_fullname', ('email='+$(this).val()));
      });

      //when updating invitations, after entering a vendor's email, list the vendors name next to his or her email.
      $('input[id="invitation_vendor_email"]').live('railsAutocomplete.select', function(event, data){
        $('#vendor_name').load('/invitations/get_fullname', ('email='+$(this).val()));
      });

      //when reviewing an evaluation request, update the accompanying gantt chart when a task duration changes.
      $('#evaluation_request_timeline').find('input, select').live('change', function(){
        if ($(this).val().length===0) {
          alert('You must have a value for the duration.  The value will be reset to 1.');
          var el = $(this);
          el.val(1);
          setTimeout(function(){
            el.trigger('focus')
          },1);
          $(this).focus();
        }
        else {
          $('#evaluation_request_timeline').load('/workflows/revise_timeline', $(this).closest('td').find('input, select').add($(this).closest('form').find('input[id="evaluation_institution_id"]')).serialize());
        }
      });
      $('#evaluation_request_timeline').find('input, select').live('blur', function(){
        if ($(this).val().length===0 && $(this).parents('#evaluation_request_timeline').length>0) {
          alert('You must have a value for the duration.  The value will be reset to 1.');
          var el = $(this);
          el.val(1);
          setTimeout(function(){
            el.trigger('focus')
          },1);
          return false;
        }
      });

      $('#review_evaluation_request').find('input[type="button"], input[type="submit"]').click(function(event){
        if (!($(this).val() in {'Deny Request':1,'Go Back':1}) && $(this).closest('td').find('div#deadline_flag').attr('deadline_flag')==='true') {
          check_total_duration_against_vendor_request();
        }
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
      $('form[id^="edit_evaluation_institution"]').find('input').filter(function(){
         return this.id.match(/evaluation_institution_financial_scenarios_attributes_\d+_fs_products_attributes_\d+_extended_cost/);
        })
        .each(function(){
          extended_cost(this);
        });

      $('form[id^="edit_evaluation_institution"]').find('fieldset').each(function(){
        adjusted_total(this);
      })

      update_extended_cost_on_change($('form[id^="edit_evaluation_institution"]'));

      $('input').filter(function() {
        return this.id.match(/evaluation_institution_financial_scenarios_attributes_\d+_discount/);
        })
        .change(function(){
          var discount = parseInt($(this).val())/100;
          $(this).closest('fieldset').find('input[id$="unit_cost"]').each(function(){
            $(this).closest('fieldset').find('input[id$="unit_cost"]').each(function(){
              var list_price = parseInt($(this).closest('tr').find('input[id$="list_price"]').val());
              var new_unit_cost = CurrencyFormatted( Math.round(list_price * (1-discount)*100)/100 );
              $(this).val(new_unit_cost);
              $(this).closest('tr').find('div.unit_cost_calculated_from_discount').html(new_unit_cost);
              extended_cost(this);
            });
          });
       });

       $('.add_financial_scenario').live('click',function(){
        var current_scenario_number = $('span.scenario_number').filter(':last').text();
        var new_fieldset = copy_fieldset($(this));
        new_fieldset.show();
        new_fieldset.find('tr.fields').each(function(){
          $(this).remove();
        });
        new_fieldset.find('.add_fs_product').click(function(){
          add_fs_product(this);
         });
        new_fieldset.find('span.total_annual_cost').html('');
        add_fs_product($(this).find('.add_fs_product').toArray());
        var scenario_number = parseInt(new_fieldset.find('span.scenario_number').text())+1;
        var legend = new_fieldset.find('legend');
        legend.html('Scenario <span class="scenario_number">'+scenario_number+'</span>:');
        new_fieldset.find('div.scenario_name').show();
        new_fieldset.find('.add_financial_scenario_button').show().find('.delete_financial_scenario').show();
        new_fieldset.find('.add_financial_scenario_button').find('input[id$="_destroy"]').val(0);
        new_fieldset.find('input[id$="_id"]').filter(':first').val('');
        new_fieldset.find('input[id$="use_a_discount"]').removeAttr('checked').closest('div').next('div').hide();;
       });
       $('.add_fs_product').click(function(){
        new_product = add_fs_product(this);
       });

      $('input[id$="use_a_discount"]').each(function(){
        toggle_unit_cost(this);
      });

      $('input[id$="use_a_discount"]').live('change', function(){
       toggle_unit_cost(this);
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
*/
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

  function update_extended_cost_on_change(link){
      $(link).find('input').filter(function() {
      return this.id.match(/evaluation_institution_financial_scenarios_attributes_\d+_fs_products_attributes_\d+_unit_cost/);
      })
      .change(function(){
        extended_cost(this);
        adjusted_total(this);
     });

      $(link).find('input').filter(function() {
      return this.id.match(/evaluation_institution_financial_scenarios_attributes_\d+_fs_products_attributes_\d+_list_price/);
      })
      .change(function(){
        var use_a_discount = $(this).closest('fieldset').find('input[name$="use_a_discount\]"]').is(':checked');
        if (use_a_discount){
          var discount_field = $(this).closest('fieldset').find('input').filter(function() {
            return this.id.match(/evaluation_institution_financial_scenarios_attributes_\d+_discount/);
          }).val();
          var discount = parseInt(discount_field)/100;
          var unit_cost_input = $(this).closest('tr').find('input[id$="unit_cost"]');
          var new_unit_cost = calculate_discounted_cost(unit_cost_input, discount);
          unit_cost_input.val(new_unit_cost);
          $(this).closest('tr').find('div.unit_cost_calculated_from_discount').html(new_unit_cost);
          extended_cost(this);
          adjusted_total(this);
        }
     });

    $(link).find('input').filter(function() {
      return this.id.match(/evaluation_institution_financial_scenarios_attributes_\d+_fs_products_attributes_\d+_estimated_annual_usage/);
      })
      .change(function(){
        extended_cost(this);
        adjusted_total(this);
     });


    $(link).find('input').filter(function() {
      return this.id.match(/evaluation_institution_financial_scenarios_attributes_\d+_discount/);
      })
      .change(function(){
        var use_a_discount = $(this).closest('fieldset').find('input[name$="use_a_discount\]"]').is(':checked');
        if (use_a_discount){
          var discount = parseInt($(this).val())/100;
          $(this).closest('fieldset').find('input[id$="unit_cost"]').each(function(){
            var new_unit_cost = calculate_discounted_cost(this, discount);
            $(this).val(new_unit_cost);
            $(this).closest('tr').find('div.unit_cost_calculated_from_discount').html(new_unit_cost);
            extended_cost(this);
            adjusted_total(this);
          });
        }
     });

    $(link).find('input').filter(function() {
      return this.id.match(/evaluation_institution_financial_scenarios_attributes_\d+_other_costs/);
      })
      .change(function(){
        adjusted_total(this);
     });


    $(link).find('input').filter(function() {
      return this.id.match(/evaluation_institution_financial_scenarios_attributes_\d+_anticipated_savings/);
      })
      .change(function(){
        adjusted_total(this);
     });
  }

  function toggle_unit_cost(link){
    if ($(link).is(':checked')){
      $(link).closest('div').next('div').show();
      var discount = parseInt($(link).closest('div').next('div').find('input').val())/100;
      $(link).closest('fieldset').find('input[id$="unit_cost"]').each(function(){
        var new_unit_cost = calculate_discounted_cost(this, discount);
        $(this).val(new_unit_cost);
        $(this).closest('tr').find('div.unit_cost_calculated_from_discount').show().html(new_unit_cost);
        extended_cost(this);
        $(this).closest('tr').find('div.unit_cost_from_user').hide();
      });
    }
    else {
      $(link).closest('div').next('div').hide();
      $(link).closest('tr').find('div.unit_cost_from_user').show();
      $(link).closest('tr').find('div.unit_cost_calculated_from_discount').hide();
      $(link).closest('fieldset').find('div.unit_cost_calculated_from_discount').hide();
      $(link).closest('fieldset').find('div.unit_cost_from_user').show();
    }
  }

  function calculate_discounted_cost(link, discount){
    var list_price = parseInt($(link).closest('tr').find('input[id$="list_price"]').val());
    return CurrencyFormatted( Math.round(list_price * (1-discount)*100)/100 );
  };

  function extended_cost(link){
    var usage = $(link).closest('tr').find('input').filter(function(){
      return this.id.match(/evaluation_institution_financial_scenarios_attributes_\d+_fs_products_attributes_\d+_estimated_annual_usage/);
    }).val();
    var unit_cost = $(link).closest('tr').find('input').filter(function(){
      return this.id.match(/evaluation_institution_financial_scenarios_attributes_\d+_fs_products_attributes_\d+_unit_cost/);
    }).val();
    $(link).closest('tr').find('input').filter(function(){
     return this.id.match(/evaluation_institution_financial_scenarios_attributes_\d+_fs_products_attributes_\d+_extended_cost/);
    }).val(unit_cost*usage);
    $(link).closest('tr').find('td[class="extended_cost"] span').html(CurrencyFormatted(unit_cost*usage));
    var total_annual_cost = 0;
    $(link).closest('table').find('td[class="extended_cost"] span').each(function(){
      total_annual_cost = total_annual_cost + parseFloat($(this).html());
    });
    $(link).closest('table').find('span[class="total_annual_cost"]').html(CurrencyFormatted(total_annual_cost));
  }


  function adjusted_total(link){
    var total_annual_cost = $(link).closest('fieldset').find('span[class="total_annual_cost"]').html() * 1;
    var other_costs = $(link).closest('fieldset').find('input[id$="other_costs"]').val() * 1;
    var anticipated_savings = $(link).closest('fieldset').find('input[id$="anticipated_savings"]').val();
    var adjusted_total = total_annual_cost + other_costs - anticipated_savings;
    $(link).closest('fieldset').find('span[class="adjusted_annual_cost"]').html(CurrencyFormatted(adjusted_total));
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
  //add button code for adding a new product row to financial scenarios.
  //alternative to method of adding rows used in evaluation_controller.rb. That one, based on a rails casts, embeds the js code to create the new row
  //in the button link.  It uses a helper function to render the fields for the new row, and then embeds them in js using code elsewhere in this file.
  //This approach instead takes a copy of an existing row, uses jquery to insert it into the DOM, and modifies the index values so it can be used to save
  //new rows.  It should be simpler to set up and has the advantage of not being as brittly dependent on DOM position.
  //This particular example is complicated because the fields change for a product that was not part of the
  //original evaluation (won't happen often, but give flexibility to analysis).
  function add_fs_product(link){
    var fsindex = get_1st_index($(link).closest('fieldset').find('input').filter(':first'));
    //if at least one row exists in the new financial scenario, copy the last row from that.  That way, we'll pick up the right product index
    if ($(link).closest('fieldset').find('tr.fields').length > 0){
      var new_tr = copy_row($(link).closest('fieldset').find('tr.fields').filter(':last'), link);
    }
    //otherwise, copy the first row from the first scenario - we'll be changing all the important details, so that row will work as well as any
    else {
      var new_tr = copy_row($('fieldset').eq(0).find('tr.fields').eq(0), link);
      new_tr.find('input, select').each(function(){
        var old_id = this.id;
        //replace first occurrence of a number (dont want to change anything but the lowest nested attribute)
        var new_id = old_id.replace(/\d/,fsindex);
        this.id = new_id;
        var old_name = this.name;
        var new_name = old_name.replace(/\d/,fsindex);
        this.name = new_name;
      });
    }
    new_tr.css("display","");
    new_tr.find('td.extended_cost').find('span').html('');
    //recalculate extended cost - do we really need to do this?
    new_tr.find('input[id$="unit_cost"], input[id$="estimated_annual_usage"]').change(function(){extended_cost(this);});
    //set financial_scenario_id
    var financial_scenario_id = $(link).closest('fieldset').find('input[id="evaluation_institution_financial_scenarios_attributes_'+fsindex+'_id"]').val();
    new_tr.find('input[id$="financial_scenario_id"]').val(financial_scenario_id);
    //change the first col from text to an input for institution
    var new_div = new_tr.find('td').filter(':first').html('<div class="input string optional">');
    var idx = parseInt(get_index(new_tr.find('input').filter(':first')));
    var input_str = '<input id="evaluation_institution_financial_scenarios_attributes_0_fs_products_attributes_1_vendor_token" class="string optional" type="text" size="25" name="evaluation_institution[financial_scenarios_attributes][0][fs_products_attributes][1][vendor_token]" data-pre="" style="display: none;">';
    input_str = input_str.replace(/\d+(?=_fs_products_attributes)/g,fsindex);
    input_str = input_str.replace(/\d+(?=\]\[fs_products_attributes)/g,fsindex);
    input_str = input_str.replace(/\d+_vendor_token/,idx+"_vendor_token");
    input_str = input_str.replace(/\d+\]\[vendor_token/,idx+"][vendor_token");
    new_div.find('div').html(input_str);

    //change the second field from text to an input for catalogue number
    new_div = new_tr.find('td').eq(1).html('<div class="input string optional">');
    input_str = '<input id="evaluation_institution_financial_scenarios_attributes_0_fs_products_attributes_1_catalogue_number" class="string optional" type="text" size="8" name="evaluation_institution[financial_scenarios_attributes][0][fs_products_attributes][1][catalogue_number]" data-pre="" >';
    input_str = input_str.replace(/\d+(?=_fs_products_attributes)/g,fsindex);
    input_str = input_str.replace(/\d+(?=\]\[fs_products_attributes)/g,fsindex);
    input_str = input_str.replace(/\d+_catalogue_number/,idx+"_catalogue_number");
    input_str = input_str.replace(/\d+\]\[catalogue_number/,idx+"][catalogue_number");
    new_div.find('div').html(input_str);

    //change the third field from text to an input for name
    new_div = new_tr.find('td').eq(2).html('<div class="input string optional">');
    input_str = '<input id="evaluation_institution_financial_scenarios_attributes_0_fs_products_attributes_1_name" class="string optional" type="text" size="8" name="evaluation_institution[financial_scenarios_attributes][0][fs_products_attributes][1][name]" data-pre="" >';
    input_str = input_str.replace(/\d+(?=_fs_products_attributes)/g,fsindex);
    input_str = input_str.replace(/\d+(?=\]\[fs_products_attributes)/g,fsindex);
    input_str = input_str.replace(/\d+_name/,idx+"_name");
    input_str = input_str.replace(/\d+\]\[name/,idx+"][name");
    new_div.find('div').html(input_str);

    //change the fifth field from text to an input for unit of measure
    new_div = new_tr.find('td').eq(4).html('<div class="input select optional">');
    input_str = '<select id="evaluation_institution_financial_scenarios_attributes_0_fs_products_attributes_2_unit_of_measure" class="select optional" width="5" name="evaluation_institution[financial_scenarios_attributes][0][fs_products_attributes][2][unit_of_measure]"><option value=""></option><option value="each">each</option>     <option value="box">box</option><option value="pack">pack</option><option value="case">case</option><option value="other">other</option></select>';
    input_str = input_str.replace(/\d+(?=_fs_products_attributes)/g,fsindex);
    input_str = input_str.replace(/\d+(?=\]\[fs_products_attributes)/g,fsindex);
    input_str = input_str.replace(/\d+_unit_of_measure/,idx+"_unit_of_measure");
    input_str = input_str.replace(/\d+\]\[unit_of_measure/,idx+"][unit_of_measure");
    new_div.find('div').html(input_str);

    //change the sixth field from text to an input for list_price
    new_div = new_tr.find('td').eq(5).html('<div class="input currency optional">');
    input_str = '$<input id="evaluation_institution_financial_scenarios_attributes_0_fs_products_attributes_0_list_price" class="currency optional" type="text" size="4" name="evaluation_institution[financial_scenarios_attributes][0][fs_products_attributes][0][list_price]">';
    input_str = input_str.replace(/\d+(?=_fs_products_attributes)/g,fsindex);
    input_str = input_str.replace(/\d+(?=\]\[fs_products_attributes)/g,fsindex);
    input_str = input_str.replace(/\d+_list_price]/,idx+"_list_price");
    input_str = input_str.replace(/\d+\]\[list_price/,idx+"][list_price");
    new_div.find('div').html(input_str);

    //add the delete icon, if needed
    var delete_icon_present = new_tr.find('input[id$="destroy"]').length;
    if (!delete_icon_present){
      var delete_icon = '<td><span class="fl notfirst"><input id="evaluation_institution_financial_scenarios_attributes_0_fs_products_attributes_2__destroy" type="hidden" value="false" name="evaluation_institution[financial_scenarios_attributes][0][fs_products_attributes][2][_destroy]"><a onclick="remove_fields(this); return false;" href="#">'
      //replaces all numbers, although we only want the first. OK, because the next command replaces the second number
      delete_icon = delete_icon.replace(/\d+(?=_fs_products_attributes)/g,fsindex);
      input_str = input_str.replace(/\d+(?=\]\[fs_products_attributes)/g,fsindex);
      delete_icon = delete_icon.replace(/\d+__destroy/g,idx+"__destroy");
      delete_icon = delete_icon.replace(/\d+\]\[_destroy/g,idx+"][_destroy");;
      delete_icon = delete_icon + '<img border="0" src="../images/delete.png" margin="-1em" alt="Delete"></a></span></td>'
      new_div = new_tr.find('td').filter(':last').after(delete_icon);
    }

    new_tr.find('input[id$="vendor_token"]').tokenInput("/institutions.json?institution_type=Vendor", {
      tokenLimit: 1,
      identifier: "vendor",
      prePopulate: $("#vendor_hospital_token").data("pre"),
      hintText: "fill in name",
      noResultsText: "vendor not found"
    });
    toggle_unit_cost(new_tr.closest('fieldset').find('input[id$="use_a_discount"]'));
    update_extended_cost_on_change(new_tr.closest('fieldset'));
    return new_tr;
    //new_tr.find('input#vendor_input_box').focus();
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
      this.id = new_id;
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
      $(this).find("input.date_picker").datepicker({ duration: 'fast',  showOn: 'both', buttonImage: '/images/datepicker.gif', buttonImageOnly: true });
    };

    $.fn.show_answers = function (){
      if ($(this).val() in {'Multiple Choice (only one answer)':1,'Multiple Choice (multiple answers)':1,'Slider':1}){
        $('#question_answers_attributes_0_text').val($('#original_choice').data('original_choice'));
        $('#answer_choice').show();
        if ($('input[id^="question_dynamically_generate"]:checked').val() in {'t':1,'true':1}){
          $('#fixed_source').hide();
          $('#dynamic_source').show();
//          $('#question_answers_attributes_0_text').val('String');
        }
      }
      else
      {
        $('#answer_choice').hide();
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
        $('#number_questions').show();
      }
      else
      {
        $('#number_questions').hide();
      }
    };

    function check_total_duration_against_vendor_request() {
      $.get(
        '/workflows/check_total_duration_against_vendor_request',
        {evaluation_institution_id: $('form').find('input[id="evaluation_institution_id"]').val()},
        function(response) {
          if (response.length > 1) {
            alert(response);
          }
        }
      );
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
        $('input[id*="hospital_token"]').filter('[id*='+new_id+']').tokenInput("/institutions.json?institution_type=Hospital", {
            tokenLimit: 1,
            identifier: "hospital",
            hintText: "fill in any combination of name, city, and state",
            noResultsText: "hospital not found"
        });
//        alert($(link).parent().prev().find('select').last().attr('id'));
       $(link).parent().prev().find('select').last().trigger('updateDynamicDropdowns');
    }

    function add_fields2(link, association, content, idx) {
        var regexp = new RegExp("new_" + association, "g");
        if (!idx) {
          var id = $(link).parent().prev().find('tr').last().find('input').last().attr('id');
          indexRegExp1 = /[0-9]+/g;
          idx  = parseInt(indexRegExp1.exec(id))+1;
          indexRegExp1.lastIndex = 0;
        };
        a=$(link).parent().prev().find('tr').last().after(content.replace(regexp, idx)).next().find('input[type!="hidden"]').first().focus();
        update_autocomplete_idx(a);
    }

    function add_fields3(link, association, content, idx) {
        var regexp = new RegExp("new_" + association, "g");
        if (!idx) {
          var id = $(link).parent().prev().find('tbody').last().find('tr').last().find('input, select').last().attr('id');
          indexRegExp1 = /[0-9]+/g;
          idx  = parseInt(indexRegExp1.exec(id))+1;
          indexRegExp1.lastIndex = 0;
        };
        $(link).parent().prev().find('tbody').last().find('tr').last().after(content.replace(regexp, idx)).next().find('input[type!="hidden"]').first().focus();
        $(link).parent().prev().find('tbody').last().find('select').trigger('updateDynamicDropdowns');
        $(link).parent().prev().find('tbody').last().find('input').trigger('updateInputs');
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
    function reason_for_deny_request() {
      $('#initial_buttons').hide();
      $('#deny_buttons').show();
      $('#revise_buttons').hide();
      $('#show_schedule').show();
      $('#revise_schedule').hide();
    }
    function revise_request() {
      $('#initial_buttons').hide();
      $('#deny_buttons').hide();
      $('#revise_buttons').show();
      $('#show_schedule').hide();
      $('#revise_schedule').show();
    }

    function show_evaluation_summary () {
      $('#evaluation_summary').show();
      $('#evaluation_summary_button').hide();
    }
    function hide_evaluation_summary () {
      $('#evaluation_summary').hide();
      $('#evaluation_summary_button').show();
    }
    function revise_evaluation () {
      $('#revision_requests').hide();
      $('#revision_form').show();
      $('#make_revisions_button').hide();
    }
    function withdraw_evaluation () {
      $('#revision_requests').hide();
      $('#withdrawal_form').show();
      $('#make_revisions_button').hide();
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
/*        var modal_response="";
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
