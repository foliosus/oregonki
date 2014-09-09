require 'pry'

module Enumerable
  # Implementation from ActiveSupport 4.0.2
  def in_groups_of(number, fill_with = nil)
    if fill_with == false
      collection = self
    else
      # size % number gives how many extra we have;
      # subtracting from number gives how many to add;
      # modulo number ensures we don't add group of just fill.
      padding = (number - size % number) % number
      collection = dup.concat([fill_with] * padding)
    end

    if block_given?
      collection.each_slice(number) { |slice| yield(slice) }
    else
      groups = []
      collection.each_slice(number) { |group| groups << group }
      groups
    end
  end
end

Array.send(:include, Enumerable)

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

  # -----------------------
  # Dojo schedules

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


  # -----------------------
  # Galleries

  def image_markup(name, link, thumbnail)
    image = image_tag(thumbnail, alt: name, width: 160, height: 106)
    image_link = link_to(image, link, title: name, rel: 'lightbox_thumbs')
    image_link + content_tag(:p, name)
  end

  # Convert fractional numbers to html entities, use &quot; to indicate inches
  def stringify_dimensions(dimensions)
    return '' unless dimensions
    dimensions.collect do |dimension|
      if dimension.is_a?(Float)
        int = dimension.to_i.to_s
        int = '' if int == '0'
        frac = dimension.modulo(1)
        int + case frac
        when 0.25 then '&frac14;'
        when 0.33 then '&frac13;'
        when 0.5 then '&frac12;'
        when 0.75 then '&frac34;'
        else frac.to_s
        end
      else
        html_escape(dimension.to_s)
      end + "&quot;"
    end.join(' x ')
  end

  def thumbnail_name(filename)
    filename.sub('/', "/thumbnails/")
  end

  def generate_thumbnail!(source_filename, thumbnail_filename)
    source_file = "#{source_dir}/#{images_dir}/#{source_filename}"
    return unless File.exists?(source_file)
    destination_file = "#{root_path}/source/#{images_dir}/#{thumbnail_filename}"
    puts "Generating #{thumbnail_filename} from #{source_filename}"
    `convert #{source_file} -thumbnail 160x106^ -gravity center -extent 160x106 -format jpg -quality 35 -unsharp 0x.5 #{destination_file}`
  end

  def gallery_image(name, number, prefix)
    content_tag(:div, class: number % 3 == 1 ? 'first' : nil) do
      filename = "galleries/#{prefix}_#{number}.jpg"
      thumbnail = thumbnail_name(filename)
      generate_thumbnail!(filename, thumbnail) unless File.exists?("#{source_dir}/#{images_dir}/#{thumbnail}")
      image_markup(name, "/#{images_dir}/#{filename}", thumbnail)
    end
  end

  def gallery(source, prefix = nil)
    images = data.photos[source]
    return content_tag(:p, 'No images found') unless images

    content_for :javascript do
      '<script type="text/javascript" src="/lightbox/prototype.js"></script>
      <script type="text/javascript" src="/lightbox/scriptaculous.js?load=effects"></script>
      <script type="text/javascript" src="/lightbox/lightbox.js"></script>'
    end
    content_for :css do
      '<link rel="stylesheet" href="/lightbox/lightbox.css" type="text/css" media="screen" />'
    end

    prefix ||= source.to_s

    output = ''
    index = 0

    images.in_groups_of(3, false) do |group|
      output += content_tag(:div, class: 'gallery_row') do
        group.collect do |name|
          index += 1
          puts index
          gallery_image(name, index, prefix)
        end.join("\n")
      end
    end

    content_tag(:div, output, class: 'gallery')
  end
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
