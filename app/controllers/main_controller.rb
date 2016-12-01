class MainController < ApplicationController
  def index
    get_rates_data
    @notify=Notify.new do |n|
      n.set_defaults
    end
    TestJob.perform_now
  end
  
  def get_rates
    respond_to do |format|
      get_rates_data
      format.js 
    end
  end
  
  private
  def get_rates_data
    if Rails.configuration.x.use_memcache
      logger.info 'get_rates_memcache'
      @rates=Rails.cache.fetch(:rates_cache_data, expires_in: CommonConst::CACHE_LIFE_TIME) do
        get_rates_from_db
      end
    else
      logger.info 'get_rates_data'
      @rates=get_rates_from_db
    end
    logger.info 'get_rates_data - end'
  end
  
  private
  def get_rates_from_db
      logger.info 'get_rates_from_db'
      rates=CurrencyRate.joins("LEFT OUTER JOIN currency_codes ON currency_rates.from_currency=currency_codes.code")
      .select("currency_rates.*,currency_codes.name as from_currency_name")
      .order(["last_update","from_currency"]).last(2)
            
      rates.each do |rate|
        rate.calc_details()
      end 
      logger.info 'get_rates_from_db - end'      
      return rates
  end
end
