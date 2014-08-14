surveyor_gui
============

THE FIRST VERSION OF THIS GEM IS UNDER DEVELOPMENT!

Surveyor_gui complements the surveyor gem.

The surveyor gem is used to create surveys by parsing a file written in the Surveyor DSL.  It does not include a gui for creating surveys, although it does provide a gui for taking surveys.

The lack of a gui front-end limits the utility of surveyor for certain applications.

Surveyor_gui meets this need by providing a gui to create surveys from scratch.  Surveyor_gui bypasses the need to create a Surveyor DSL file, and directly updates the Surveyor tables to build a survey.

Surveyor is feature-rich and can create very complex surveys.  Surveyor-gui supports most of the features in Surveyor.

This gem will also provide a reporting capability for Surveyor.

## Requirements

SurveyorGui works with:

* Ruby 1.9.3
* Rails 4


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
    gem 'surveyor_gui', github:'kjayma/surveyor_gui'

You will also need a javascript runtime, like node.js or therubyracer.  If you
have not yet installed one, add

    gem "therubyracer"

to your Gemfile.

Bundle, install, and migrate:

    bundle install
    rails g surveyor_gui:install

Note that the installer will run db:migrate (so any un-applied migrations you have in your project will be pulled in).
The survey editor can be found at '/surveyforms'.  Users can take surveys at the '/surveys' url.

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

Start the rails server and go to /surveyforms

## Taking surveys

Go to /surveys (or click the link at the bottom of the surveyforms home page) to see the surveys and take one.

## Reports

Surveyor_gui now provides reports!  

You can see a report of all survey responses, or view an individual response.

Highcharts.js is used for graphics, and must be licensed for commercial use.  Future development will replace Highcharts with Rickshawgraphs.

To see reports, try using the "Preview Reports" button on the survey editor, or take the survey and try
"localhost:3000/surveyor_gui/reports/:id/show" where :id is the survey id.  Preview reports will create some dummy
responses using randomized answers.  

You can also view an individual response at "localhost:3000/surveyor_gui/results/:id/show".

## Devise etc.

Surveyor_Gui does not provide direct support for Devise at this time, however, you can certainly hook it into
your user model.

The underlying, Surveyor gem provides a user_id attribute in the ResponseSet model.

Surveyor_gui reports assume there will be a unique user for eash Survey response, and reports on results by user.
If the response set has a user id, it will identify the response by user_id (not ideal).  If no user_id is available, it will
default to the response_set.id (even worse).

If you have a user model, you can override this behavior.  The current, but temporary, approach is to monkey patch the ResponseSet model's report_user_name method.  It will change the way user are identified on reports.  For instance, to identify users by first and last name (assuming you have a user model named User), you might do something like
this:

Add "response_set.rb" to your app/models directory.

Put the following in the file:

    class ResponseSet
      def report_user_name
        user = User.find(self.user_id)
        user.first_name + " " + user.last_name
      end
    end
