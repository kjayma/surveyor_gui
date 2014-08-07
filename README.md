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
    rails g surveyor:install
    rails g simple_form:install
    rails g surveyor_gui:install
    bundle exec rake db:migrate

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

## Locking

This gem enforces locking on surveys.  A survey may be modified up until a user submits a response.  At that point, the survey
can no longer be edited for structural changes (i.e., /surveyform/edit will not permit any changes).  This protects the
data integrity of the survey response data.

## Templates

Surveys may be saved as templates.  This allows them to be cloned when creating a new survey (cloning is a pending feature).  It is
possible to mark certain parts of a survey as unmodifiable so that they will always be present when a survey is cloned.
  
A template library feature is pending.

## Dynamic Generation

A pending feature that allows a list of answers to be dynamically generated from the database.  When creating a question, the survey creator
enters a special code that specifies the table from which to draw the answers.

## Test environment

If you want to try out surveyor-gui before incorporating it into an application, run

    bundle install
    bundle exec rake gui_testbed
    cd testbed

Start the rails server and go to /surveyforms

## Reports
Reports are currently experimental.  For now, reports can make use of basic question types, but cannot handle grid or
group questions.

Highcharts.js is used for graphics, and must be licensed for commercial use.  Planning to replace with Rickshawgraphs at
some point soon.

If you would like to try reports, replace the git URL in the installation instructions above with the following:

    gem 'surveyor_gui', github:'kjayma/surveyor_gui', :branch => 'reports'
    
after following installation instructions, perform this additional step:

    bundle exec rake highcharts:update
