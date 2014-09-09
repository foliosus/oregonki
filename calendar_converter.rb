require 'rubygems'
require 'rexml/document'
require 'ri_cal'
require 'time'

FILE_PREFIX = 'source/'
INPUT_FILE = "#{FILE_PREFIX}events.xml"
OUTPUT_FILE = "#{FILE_PREFIX}events.ics"

@debug = false

class Event
  def initialize(hash)
    @hash = hash
  end

  def hash
    @hash
  end

  def [](key)
    @hash[key]
  end

  def location
    if self[:location]
      if self[:location] =~ /,/
        "#{self[:location]} dojos"
      else
        "#{self[:location]} dojo"
      end
    else
      "all dojos"
    end
  end

  def start_date
    @date ||= begin
      parts = self[:start_date].split('/').collect(&:to_i)
      Date.new(parts[2] + 2000, parts[0], parts[1])
    end
  end

  def method_missing(name)
    @hash[name]
  end
end

def load_xml
  events = []
  File.open(INPUT_FILE, File::RDONLY) do |file|
    doc = REXML::Document.new(file)
    doc.elements.each('events/event') do |e|
      hash = {}
      ['title', 'description', 'start_date', 'start_time', 'duration', 'location', 'dojo'].each do |attrib|
        c = e.get_elements(attrib)
        if c.any?
          hash[attrib.to_sym] = c.first.text
        end
      end
      puts "#{hash.inspect}" if @debug
      events << Event.new(hash)
    end
  end
  events
end

def convert_events_to_calendar(event_list, title = "Oregon Ki Society")
  RiCal.Calendar do |cal|
    cal.add_x_property 'x_wr_calname', title
    event_list.each do |e|
      cal.event do |ev|
        ev.summary = e.title
        ev.description = e.description
        e.start_date
        ev.dtstart = e.start_date
        if e.duration
          ev.dtend = e.start_date + e.duration.to_i
        else
          ev.dtend = e.start_date
        end
        ev.location = e.location if e.location
        ev.description = "#{e.start_time}\n\n#{e.description}" if e.start_time
      end
    end
  end
end

def write_calendar(calendar, output_file = OUTPUT_FILE)
  print "Writing #{calendar.events.length} events to #{output_file}... "
  File.open(output_file, mode: 'w+') do |file|
    file.write(calendar.to_s)
  end
  puts "done"
end

def load_dojos
  Dir.glob('*.php.haml').collect{|f| f.sub('.php.haml', '')}
end

def filter_events_for_dojo(events, dojo)
  events.select do |event|
    event.dojo.nil? || event.dojo.include?(dojo_token_to_name(dojo))
  end
end

def dojo_token_to_name(dojo)
  dojo.gsub('_', ' ').capitalize.sub('Se ', 'SE ')
end


puts "******************************************"
puts "** Converting calendars from xml to ics **"
puts "******************************************"

events = load_xml
puts "Loaded #{events.length} events from #{INPUT_FILE}"

cal = convert_events_to_calendar(events)
write_calendar(cal)

Dir.chdir("#{FILE_PREFIX}/locations")

dojos = load_dojos

dojos.each do |dojo|
  dojo_events = filter_events_for_dojo(events, dojo)
  cal = convert_events_to_calendar(dojo_events, "Oregon Ki Society: #{dojo_token_to_name(dojo)} dojo")
  write_calendar(cal, "#{dojo}.ics")
end

puts "******************************************"
puts "**     Calendar conversion complete     **"
puts "******************************************"
puts
puts
