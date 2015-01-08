# README

This site requires <a href="https://www.ruby-lang.org/en/">Ruby 2.2.0</a> with the <a href="http://rubygems.org/gems/rake">rake</a> and <a href="http://rubygems.org/gems/bundler">bundler</a> gems installed. It's based on <a href="https://middlemanapp.com/">middleman</a>, a great tool for generating static sites. To get started, assuming you have a working Ruby installation:

    bundle install
    bundle exec middleman start

You'll then be able to load pages from http://localhost:4567.

## Development

Work in the `/source` directory.

### Data sources

The photo galleries are built out of `/data/photos.yml`, and the dojo course schedules are built from the data in `/data/schedule.yml`.

To edit the calendars, edit `\source\events.xml`. The downloadable `.ics` files will be generated when you run a build (see below).

### Builds

To create a build, run:

    bundle exec middleman build

That will generate the static site files, suitable for pushing up to the server.