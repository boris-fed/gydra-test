class MainController < ApplicationController
  def index
    get_rates_data
    @notify=Notify.new do |n|
      n.set_defaults
    end
  end
  
  def get_rates
    respond_to do |format|
      get_rates_data
      format.js 
    end
  end
  
  def load_rates
    RatesUploadJob.perform_now
    redirect_to root_path
  end
  
  private
  def get_rates_data
    if Rails.configuration.x.use_memcache
      @rates=Rails.cache.fetch(:rates_cache_data, expires_in: CommonConst::CACHE_LIFE_TIME) do
        get_rates_from_db
      end
    else
      @rates=get_rates_from_db
    end
  end
  
  private
  def get_rates_from_db
      rates=CurrencyRate.joins("LEFT OUTER JOIN currency_codes ON currency_rates.from_currency=currency_codes.code")
      .select("currency_rates.*,currency_codes.name as from_currency_name")
      .order(["last_update","from_currency"]).last(2)
            
      rates.each do |rate|
        rate.calc_details()
      end 
      return rates
  end
end
