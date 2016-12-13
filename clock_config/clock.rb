require 'clockwork'
require './config/boot'
require './config/environment'

module Clockwork
  handler do |job|
    puts "Running #{job}"
    "#{job}".constantize.perform_later
  end
  every(15.seconds, 'RatesUploadJob')
end

