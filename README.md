surveyor_gui
============

THE FIRST VERSION OF THIS GEM IS UNDER DEVELOPMENT!

Surveyor_gui complements the surveyor gem.

The surveyor gem is used to create surveys by parsing a file written in the Surveyor DSL.  It does not include a gui for creating surveys, although it does provide a gui for taking surveys.

The lack of a gui front-end limits the utility of surveyor for certain applications.

Surveyor_gui meets this need by providing a gui to create surveys from scratch.  Surveyor_gui bypasses the need to create a Surveyor DSL file, and directly updates the Surveyor tables to build a survey.

Surveyor is feature-rich and can create very complex surveys.  Surveyor-gui does not support the full feature set of Surveyor, as it aims to
create a simple to use front-end that easily can be mastered by an end user.  It still provides quite a bit of power, but sacrifices some
of Surveyor's breadth in exchange for ease-of-use.

This gem will also provide a reporting capability for Surveyor.

## Requirements

Surveyor works with:

* Ruby 1.9.3
* Rails 3.2

In keeping with the Rails team maintenance [policy] we no longer support Rails 3.0 (stick with v1.3.0 if you need Rails 3.0) or Ruby 1.8.7 (stick with v1.4.0 if you need Ruby 1.8.7).

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

Add surveyor-gui to your Gemfile:

    gem "surveyor-gui"

You will also need a javascript runtime, like node.js or therubyracer.  If you
have not yet installed one, add

    gem "therubyracer"

to your Gemfile.

Bundle, install, and migrate:

    bundle install
    rails g surveyor-gui:install
    bundle exec rake db:migrate

The survey editor can be found at '/surveyforms'.  Users can take surveys at the '/surveys' url.

## Limitations

This gem provides support for a subset of the Surveyor functionality.  It supports all of the basic question types, but does
not currently support the following:

  - Question groups
  - Questions with multiple entries (e.g., the "Get me started on an improv sketch" question in the kitchen_sink_survey.rb that comes
    with the Surveyor gem.
  - Grid questions
  - Datetime
  - Exclusive answers
  - Input masks
  - Rankings
  - Other type questions (e.g., the "Choose your favorite utensils and enter frequency of use (daily, weekly, monthly, etc...)"
    in kitchen_sink_survey.rb
  - Repeaters
  - Quizzes

It adds some new question types:

  - Star rating (1-5 stars)
  - File upload

These new question types will be supported in a modified version of the surveyor views which is pending.

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
