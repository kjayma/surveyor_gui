surveyor_gui 
============

current version =  0.2.2

Some differences with the surveyor_gui fork:

* surveyor:  uses the [weedySeaDragon/ae-surveyor](https://github.com/weedySeaDragon/ae-surveyor) fork of the [NUBIC **surveyor** gem](https://nubic.github.io/surveyor/)
  - is recently updated

 
* uses jquery-ui-rails instead of jquery-ui-sass-rails 
 
* fixes some RSpec testing issues:
  - doesn't install this _and_ surveyor (which causes Surveyor to show up twice in the routes.rb file)
  - updates to RSpec 3+  (including code changes under `/spec/`). Note that `/spec/features` still fail


## Requirements
- ruby 2.4.0



---
---

*From the original README:*

## Add Surveys to your Rails application

Need a way to quickly add surveys to your Rails application?  Need a way for users to create customizable surveys with little or no training?  Need reports and graphs out of the box?  Don't want to use a third-party service or closed solution?

Surveyor_gui can help!

You can add surveyor_gui to a new or existing rails application to provide a way to create and administer surveys.

You can find some screenshots at the bottom of this README.

Builds on the popular Surveyor gem
============

Surveyor_gui is built over Surveyor gem.

Surveyor does some things really well.  Surveyor can be used to build rich surveys with a wide variety of questions types, and it provides a web page for users to take those surveys.  However, it lacks two key abilities - the ability to build and edit surveys using a browser and to report on survey results without additional coding.  In order to build a survey using Surveyor, you need to create a text file using Surveyor's DSL, and then call a Rake task to parse it.  

The lack of a gui front-end and reports limits the utility of surveyor for certain applications.

Surveyor_gui meets this need by providing a gui to create surveys from scratch.  Surveyor_gui bypasses the need to create a Surveyor DSL file, and directly updates the Surveyor tables to build a survey.

Surveyor is feature-rich and can create very complex surveys.  Surveyor-gui supports most of the features in Surveyor.

This gem also provides a reporting capability for Surveyor.

Surveyor_gui is a mountable engine.

## Requirements (for OLDER versions of the gem / original forks)

SurveyorGui works with:

* Ruby 1.9.3
* Rails 4, 4.1


Some key dependencies are:

* Surveyor
* HAML
* Sass
* Formtastic

A more exhaustive list can be found in the gemspecs for Surveyor [surveyor] and Surveyor_gui [surveyor-gui][].

[surveyor]: https://github.com/NUBIC/surveyor/blob/master/surveyor.gemspec
[surveyor-gui]: https://github.com/kjayma/surveyor_gui/blob/master/surveyor_gui.gemspec
[policy]: http://weblog.rubyonrails.org/2013/2/24/maintenance-policy-for-ruby-on-rails/

## Install

Add surveyor and surveyor-gui to your Gemfile:

    gem 'surveyor', github: 'NUBIC/surveyor'
    gem 'surveyor_gui'

You will also need a javascript runtime, like node.js or therubyracer.  If you
have not yet installed one, add

    gem "therubyracer"

to your Gemfile.

Bundle, install, and migrate:

    bundle install
    rails g surveyor_gui:install

Note that the installer will run db:migrate (so any un-applied migrations you have in your project will be pulled in).

You will need to add mountpoints to your routes.rb file.  E.g., a starting routes.rb might look like this:


    Rails.application.routes.draw do
      mount SurveyorGui::Engine => "/surveyor_gui", :as => "surveyor_gui"
      mount Surveyor::Engine => "/surveys", :as => "surveyor"
    end

SurveyorGui::Engine points to the survey editor.  Surveyor::Engine points to the url where users will take the surveys.
The routes.rb file in the testbed application (see Test Environment section) uses the default mountpoints noted above, however
they are arbitrary and can be change to anything you would prefer (e.g., mount SurveyorGui::Engine => "my/survey/engine", :as => "surveyor_gui").

## Limitations

This gem provides support for a subset of the Surveyor functionality.  It supports all of the basic question types, and
most of the complicated question types, but does not currently support the following:

  - Questions with multiple entries (e.g., the "Get me started on an improv sketch" question in the kitchen_sink_survey.rb that comes
    with the Surveyor gem.
  - Input masks
  - Quizzes

It adds some new question types:

  - Star rating (1-5 stars)
  - File upload
  - Grid dropdown (a grid of dropdowns with up to ten columns.)

Dependencies are partially supported.  The following are not currently supported:

- counts (count the number of answers checked or entered)
- Regexp validations

You can open the kitchen_sink survey that comes with Surveyor, but a few of the questions will not behave as expected
because of the discrepancies noted above.

## Locking

This gem enforces locking on surveys.  A survey may be modified up until a user submits a response.  At that point, the survey
can no longer be edited for structural changes (i.e., /surveyform/edit will not permit any changes).  This protects the
data integrity of the survey response data.

If you want to unlock a survey, you will need to manually delete all of the child ResponseSet records (e.g.,
Survey.find(1).response_set.all.each{|r| r.destroy} ). Use appropriate caution!

## Templates

Surveys may be saved as templates.  This allows them to be cloned when creating a new survey (cloning is a pending feature).  It is
possible to mark certain parts of a survey as unmodifiable so that they will always be present when a survey is cloned.
  
A template library feature is pending.

## Test environment

If you want to try out surveyor-gui before incorporating it into an application, or contribute, clone the repository.
Then run

    bundle install
    bundle exec rake gui_testbed
    cd testbed

Start the rails server.

The survey editor can be found at '/surveyor_gui/surveyforms'.  Take surveys by going to the '/surveys' url or clicking the
link at the bottom of the surveyforms home page.

Before contributing, please run the tests:
    bundle exec rspec spec

## Reports

Surveyor_gui now provides reports!  

You can see a report of all survey responses, or view an individual response.

Highcharts.js is used for graphics, and must be licensed for commercial use.  Future development will replace Highcharts with Rickshawgraphs.

To see reports, try using the "Preview Reports" button on the survey editor, or take the survey and try
"localhost:3000/surveyor_gui/reports/:id/show" where :id is the survey id.  Preview reports will create some dummy
responses using randomized answers.  

You can also view an individual response at "localhost:3000/surveyor_gui/results/:id/show".

## Use of Devise and additional customization

### Devise
Surveyor_Gui will work with Devise or like gems.

Surveyor_gui adds a user_id attribute to the Survey model.  It will try to set user_id to current_user when a new survey
is defined.  The gem does not provide any access control over survey creation and update, but you can add that to your
application using the user_id attribute.

In addition, the underlying Surveyor gem provides a user_id attribute in the ResponseSet model.  When responses are created, it will
try to set the user_id to current_user.

Surveyor_gui reports assume there will be a unique user for eash Survey response, and reports on results by user.
If the response set has a user id, (which will be the case if you've setup Devise in the typical way) it will identify the response by user_id.  If no user_id is available, it will
default to the response_set.id.

You may want to identify users by something other than id on reports.  This can be done easily.  

Surveyor_gui creates a response_set_user.rb file in your app/models directory.  Edit it to define the identifier you would like to use for users in reports.  For instance, if your user model is User, and you would like to see the user's email address on reports, edit the file as follows...

In the initialize method, add the following line:

    @user = User.find(user_id)

In the report_user_name method, add the following line:

    @user ? @user.email : nil

If you wanted the users full name, you could add something like this:

    @user ? @user.last_name + ', ' + @user.first_name : nil

Note that SurveyorGui controllers expect to use surveyor_gui's own layout view, surveyor_gui_default.rb.  A copy will be placed in your application's app/views/layouts directory.  You may need edit it for various reasons, such as adding a Devise login/logout link.  Keep in mind that surveyor_gui works in an isolated namespace, so devise helpers need to be namespaced to the main app. That means that any view local to surveyor_gui would need to refer to Devise's new_user_registration_path as main_app.new_user_registration_path.  If you wanted to add a login/logout link to the surveyor_gui_default layout, you might add something like this:

    <% if user_signed_in? %>
      Logged in as <strong><%= current_user.email %></strong>.
      <%= link_to 'Edit profile', main_app.edit_user_registration_path %> |
      <%= link_to "Logout", main_app.destroy_user_session_path, method: :delete %>
    <% else %>
      <%= link_to "Sign up", main_app.new_user_registration_path %> |
      <%= link_to "Login", main_app.new_user_session_path %>
    <% end %>

### Additional Customization

If you need to perform more extensive customization of Surveyor_gui, take a look at NUBIC/surveyor for customization documentation.  The process of customizing Surveyor_gui is largely the same.  There are a couple of points to keep in mind.  As mentioned above, Surveyor_gui expects its own layout view.  If you need to change it or override the default layout in your own custom SurveyorController, make sure to add the following html (or HAML equivalent):

     <div id="surveyor-gui-mount-point" data-surveyor-gui-mount-point="<%= surveyor_gui.surveyforms_path %>"></div>

This snippet of code allows the javascript files to find the correct mountpoint for the Surveyor_gui gem, which, as mentioned above, may be modified to suit your needs.  You will also need to add javascript and stylesheet include tags for surveyor_gui_all.

If you wish to customize the SurveyorController, add the following snippet to the top of your conroller:

     include Surveyor::SurveyorControllerMethods
     include SurveyorControllerCustomMethods
 
These statements are necessary if calling super from within your customized methods.  Be sure to insert the statements in the order shown above.

If customizing models, you'll need to include both the Surveyor and Surveyor_gui libraries.  For instance, to customize question.rb, start with the following shell:

    class Question < ActiveRecord::Base
      include Surveyor::Models::QuestionMethods
      include SurveyorGui::Models::QuestionMethods
    end

Take a look at the surveyor_gui/app/models directory for examples.    

## Surveyor

Please take a look at the NUBIC/surveyor on github.  The README.doc file will help you to understand how the surveyor engine works.  Also, the wiki has a very useful data diagram that will help you to grasp the data
structure of the surveys and responses.


## Screenshots

### Manage surveys

![](https://raw.github.com/kjayma/surveyor_gui/screenshots/Screenshot%20from%202014-09-16%2016:54:18.png)

### Build surveys

![](https://raw.github.com/kjayma/surveyor_gui/screenshots/Screenshot%20from%202014-09-16%2016:59:36.png)

### Add questions

![](https://raw.github.com/kjayma/surveyor_gui/screenshots/Screenshot%20from%202014-09-16%2017:03:57.png)

### Get reports

![](https://raw.githubusercontent.com/kjayma/surveyor_gui/screenshots/Screenshot%20from%202014-09-16%2017:04:41.png)
