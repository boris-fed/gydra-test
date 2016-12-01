require 'clockwork'
require './config/boot'
require './config/environment'

module Clockwork
  handler do |job|
    puts "Running #{job}"
    "#{job}".constantize.perform_later
  end
  every(CommonConst::LOAD_RATES_INTERVAL, 'RatesUploadJob')
end

