#!/usr/bin/ruby

# debug = false
# environment = "production"
# 
# for i in (0...(ARGV.count)) do
#   if ARGV[i].include? "debug"
#     debug = true
#   elsif ARGV[i].include? "environment"
#     environment = ARGV[i+1]
#     i += 1
#   elsif ARGV[i].to_s.include? "help"
#     puts "Usage: ./ghetto_bg_processing.rb [--debug] [--environment development]\n"
#     puts "Debug runs poller as a non-daemon process."
#     puts "Environment specifies which parameters to pick from the config."
#     exit
#   end
# end
# 
# 
# # Get path to log file before daemonizing
# log_file = File.expand_path(File.dirname(__FILE__)).to_s + "/bg_processor_#{environment}.log"
# 
# if debug
#   logger = Logger.new STDOUT
#   logger.info "Starting in debug mode."
# else
#   puts "Starting daemon."
#   Daemons.daemonize
#   logger = Logger.new log_file, 10, 1024000
#   logger.info "Poller started."
# end






require "config/environment"
require "securerandom"

def process_page(page)
  begin
    page.process_images
  rescue Exception => e
    puts "Error in process_page #{$!}, #{e.backtrace.first.inspect}"
  end
  page.save
end

# Main loop
while true
  page = Page.find(:all, :limit=>1, :conditions=>["image_processing_started = false"]).first
  if page.nil?
    sleep 1
  else
    puts "Processing page: #{page.id}"
    process_page page
    puts "Finished job."
  end
end