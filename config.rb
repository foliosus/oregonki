require 'pry'

###
# Page options, layouts, aliases and proxies
###

# Per-page layout changes:
#
# With no layout
# page "/path/to/file.html", :layout => false
#
# With alternative layout
# page "/path/to/file.html", :layout => :otherlayout
#
# A path which all have the same layout
# with_layout :admin do
#   page "/admin/*"
# end

with_layout 'layout' do
  page '*.html'
  page '*.php'
end

# Proxy pages (http://middlemanapp.com/basics/dynamic-pages/)
# proxy "/this-page-has-no-template.html", "/template-file.html", :locals => {
#  :which_fake_page => "Rendering a fake page with a local variable" }

###
# Helpers
###

# Automatic image dimensions on image_tag helper
activate :automatic_image_sizes

# Reload the browser automatically whenever files change
configure :development do
  activate :livereload
  activate :php
end

# Methods defined in the helpers block are available in templates
helpers do
  # Include a PHP script into the page.
  # The middleman-php dev environment has different pathing requirements, so
  # we switch out the path based on where we're running.
  def php_include(filename)
    if build?
      "<?php include_once('./scripts/#{filename}'); ?>"
    else
      "<?php include_once('./source/scripts/#{filename}'); ?>"
    end
  end

  # Parameters
  # course[:time] is "6:30 pm" or anything parsable by Time.
  # course[:duration] is the duration in minutes. Defaults to 60 minutes (1 hour).
  def course_time(course)
    start = Time.parse(course[:time])
    finish = start + (course[:duration] || 60) * 60
    "#{start.strftime('%l:%M').strip}&ndash;#{finish.strftime('%l:%M %P').strip}"
  end

  # Output a dojo schedule table, given a dojo name, eg :tigard
  def dojo_schedule(dojo)
    schedule = data.schedule[dojo]

    odd = true
    has_location = false
    rows = ''
    content_tag :table, cellspacing: 0 do
      [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday].each do |day|
        next unless schedule[day]
        courses = schedule[day].is_a?(Array) ? schedule[day] : [schedule[day]]
        courses.each do |course|
          rows += content_tag(:tr, class: (odd ? 'odd' : 'even')) do
            row = content_tag(:td, course == courses.first ? day.to_s.capitalize : '') +
                  content_tag(:td, course[:description]) +
                  content_tag(:td, course_time(course))
            if course[:location]
              has_location = true
              row += content_tag(:td, course[:location])
            end
            row
          end
        end
        odd = !odd
      end

      heading = content_tag(:tr) do
        content_tag(:th, 'Day') + content_tag(:th, 'Class') + content_tag(:th, 'Time') + (has_location ? content_tag(:th, 'Location') : '')
      end

      content_tag(:thead, heading) + content_tag(:tbody, rows)
    end
  end # dojo_schedule
end

set :css_dir, 'stylesheets'
set :js_dir, 'javascripts'
set :images_dir, 'images'

# Build-specific configuration
configure :build do
  # For example, change the Compass output style for deployment
  activate :minify_css

  # Minify Javascript on build
  activate :minify_javascript

  # Enable cache buster
  activate :asset_hash

  # Use relative URLs
  activate :relative_assets
end

before_build do
  puts `ruby calendar_converter.rb`
end
