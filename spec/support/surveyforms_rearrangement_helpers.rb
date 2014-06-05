module CutAndPaste
  def construct_scenario
    examples = """
    |from_item     | over_under | to_item     | order|
    |2             | over       | 1           | 213  |
    |2             | over       | 3           | 123  |
    |2             | under      | 1           | 123  |
    |2             | under      | 3           | 132  |
    |1             | over       | 2           | 312  |
    |1             | over       | 3           | 132  |
    |1             | under      | 2           | 321  |
    |1             | under      | 3           | 312  |
    |3             | over       | 1           | 312  |
    |3             | over       | 2           | 132  |
    |3             | under      | 1           | 132  |
    |3             | under      | 2           | 123  |
    """
    #ScenarioOutline class found in spec/support/scenario_outline_helpers.rb
    #use to simulate Cucumber type Scenario Outline
    ScenarioOutline.new(examples)
  end

  def run_scenario
    @scenario.examples.each do |example|
      #e.g. puts "cut Unique Question 1 and paste it under Unique Question 2 resulting in 213"
      puts "\tcut #{example.from_item} \
              and paste it #{example.over_under} #{example.to_item}\
              resulting in #{example.order}"
      cut_and_paste_one_item(example)
    end
  end

  def cut_and_paste_one_item(example)
    _cut_item("Unique #{@item_name} "+example.from_item)
    _paste_item(example.over_under, "Unique #{@item_name} "+example.to_item)
    _check_order(example.order)
  end

  def cut_question(question)
    cut_button = "$('fieldset.questions:contains(\"#{question}\") button:contains(\"Cut Question\")')[0].click();"
    #When I cut <from_item>
    page.execute_script(cut_button)
    expect(page).not_to have_css('div.jquery_cut_question_started')
    #Then I see paste buttons appear
    expect(page).to have_content('Paste Question')
  end

  def cut_section(section)
    cut_button = "$('div.survey_section:contains(\"#{section}\") button:contains(\"Cut Section\")')[0].click();"
    #When I cut <from_item>
    page.execute_script(cut_button)
    expect(page).not_to have_css('div.jquery_cut_section_started')
    #Then I see paste buttons appear
    expect(page).to have_content('Paste Section')
  end

  def paste_section(position, section)
    #And paste it <over_under> <to_item>
    @_click_prev_paste_button_js = method(:_click_prev_paste_section_button_js)
    @_click_next_paste_button_js = method(:_click_next_paste_section_button_js)
    page.execute_script(_click_paste_button_js(position, section))
    expect(page).not_to have_css('div.jquery_paste_section_started')
    #Then I see cut buttons return
    sleep 1
    expect(page).to have_content('Cut Section')
  end

  def paste_question(position, question)
    #And paste it <over_under> <to_item>
    @_click_prev_paste_button_js = method(:_click_prev_paste_question_button_js)
    @_click_next_paste_button_js = method(:_click_next_paste_question_button_js)
    page.execute_script(_click_paste_button_js(position, question))
    expect(page).not_to have_css('div.jquery_paste_question_started')
    #Then I see cut buttons return
    expect(page).to have_content('Cut Question')
  end

  def _click_paste_button_js(position, item)
    if position == "over"
      @_click_prev_paste_button_js.call(item)
    else
      @_click_next_paste_button_js.call(item)
    end
  end


  def _click_prev_paste_question_button_js(question)
    #If the target question is the first in the section, the previous button will
    #be found in the button bar div.  This div is one level up and one position back in the DOM.
    #Otherwise, it will be found at the bottom of the previous question (div.question).
    """
    var to_item = $('fieldset.questions:contains(\"#{question}\")').closest('div.question');
    var prev_question_in_section = to_item.prev('div.question');
    if (prev_question_in_section.length < 1) {
      prev_button_bar = to_item.closest('div.sortable_questions').prev('div.question_buttons_top');
      prev_button = prev_button_bar.find('button:contains(\"Paste Question\")')[0];
    } else {
      prev_button = prev_question_in_section.find('button:contains(\"Paste Question\")')[0];
    }
    prev_button.click();

    """
  end

  def _click_next_paste_question_button_js(question)
    """
    $('fieldset.questions:contains(\"#{question}\")').closest('div.question')
    .find('button:contains(\"Paste Question\")')[0].click();
    """
  end

  def _click_prev_paste_section_button_js(section)
    """
    $('div.survey_section:contains(\"#{section}\") div.section_top_button_bar button:contains(\"Paste Section\")')[0].click();
    """
  end

  def _click_next_paste_section_button_js(section)
    """
    $('div.survey_section:contains(\"#{section}\") div.section_button_bar_bottom_inner button:contains(\"Paste Section\")')[0].click();
    """
  end

  def _check_order(order)
    exp = ".*"
    order.split("").each do |question|
      exp += "Unique #{@item_name} #{question}.*"
    end
    regexp = Regexp.new exp
    #Then I see the questions in the correct order
    expect(page).to have_content(regexp)
  end
end

shared_context "question_cut_and_paste" do
  include CutAndPaste
  def initialize
    @scenario = construct_scenario
    @item_name = "Question"
  end

  def _cut_item(question)
    cut_question(question)
  end

  def _paste_item(position, question)
    paste_question(position, question)
  end
end


shared_context "section_cut_and_paste" do
  include CutAndPaste
  def initialize
    @item_name = "Section"
    @scenario = construct_scenario
  end

  def _cut_item(section)
    cut_section(section)
  end

  def _paste_item(position, section)
    paste_section(position, section)
  end
end

shared_context "question_and_section_cut_and_paste" do
  include CutAndPaste
end
