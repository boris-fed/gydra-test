class TestJob < ActiveJob::Base
  queue_as :default
  
  def perform(*args)
    puts 'test job'
	end
end	