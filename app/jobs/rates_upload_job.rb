class RatesUploadJob < ActiveJob::Base
  queue_as :default
  
  def perform(*args)
    UploadRatesTools.upload_rates(logger, RatesUploadJob.name, Rails.configuration.x.use_queues)
  end
end

class RatesUploadResqueTask
  def self.perform(*args)
    logger=Logger.new(STDOUT)
    UploadRatesTools.upload_rates(logger, RatesUploadResqueTask.name, false)
  end
end

module UploadRatesTools

  def self.upload_rates(logger, log_class_name, use_queues)
  logger.info "#{log_class_name}: uploading currency rates from #{CommonConst::LOAD_RATES_SOURCE_URL}" 
  encoding='utf-8'
    
  begin
    if RUBY_PLATFORM=~/mswin|mingw|cygwin/
      encoding='windows-1251'
    end
    uri = URI.parse(CommonConst::LOAD_RATES_SOURCE_URL)
    response=nil
    Net::HTTP.start(uri.host, uri.port, :use_ssl => true, :verify_mode => OpenSSL::SSL::VERIFY_NONE ) do |http|
      response = http.get(uri.request_uri)
    end
   
    if response==nil || response.code != '200'
      logger.info "#{log_class_name}: no response from server"
      return
    end  
      
    data = JSON.parse(response.body)
    last_update_milliseconds=data['payload']['lastUpdate']['milliseconds']
    last_update=DateTime.strptime(last_update_milliseconds.to_s,'%Q')
    currency_rate_count=0
    cache_data=Array.new
    
    data['payload']['rates'].each do |rate|
      if rate['category']==CommonConst::LOAD_RATES_CURRENCY_CATEGORY
        from_currency_code=rate['fromCurrency']['code']
        to_currency_code=rate['toCurrency']['code']
        if to_currency_code==643 && (from_currency_code==840 || from_currency_code==978)
            currency_rate=CurrencyRate.new
            currency_rate.from_currency=from_currency_code
            currency_rate.to_currency=to_currency_code
            currency_rate.buy=rate['buy']
            currency_rate.sell=rate['sell']
            currency_rate.last_update=last_update
            currency_rate.save
            currency_rate_count+=1
            if Rails.configuration.x.use_memcache
              currency_rate.calc_details
            end
            cache_data << currency_rate
        end
      end
    end  
    if Rails.configuration.x.use_memcache
      Rails.cache.write(:rates_cache_data,cache_data,expires_in: CommonConst::CACHE_LIFE_TIME)
    end  
    logger.info "#{log_class_name}: currency rates loaded - #{currency_rate_count}"
    if Rails.configuration.x.send_notifies
      logger.info "#{log_class_name}: sending notifications"
      count=send_notify(cache_data, use_queues)
      logger.info "#{log_class_name}: notifications sent - #{count}"
    end
  rescue => e
    logger.error(e.to_s.force_encoding(encoding))
  ensure
    logger.info "#{log_class_name}: job is finished"
  end
end

def self.send_notify(rates, use_queues)
  count=0
  rates.each do |rate|
    notifies=Notify.where("currency_code=? AND operation=? AND method=? AND value<=?", rate.from_currency, :buy, '>', rate.buy)
    text="%s покупка за %s руб." % [rate.currency_name,(sprintf "%.2f", rate.buy)]
    notifies.each do |notify|
      subject="Нотификация: покупка %s дороже %s руб." % [rate.currency_name,(sprintf "%.2f", notify.value)]
      send_mail(notify.email, subject, text, use_queues)
      notify.destroy
      count+=1
    end

    notifies=Notify.where("currency_code=? AND operation=? AND method=? AND value>=?", rate.from_currency, :buy, '<', rate.buy)
    text="%s покупка за %s руб." % [rate.currency_name,(sprintf "%.2f", rate.buy)]
    notifies.each do |notify|
      subject="Нотификация: покупка %s дешевле %s руб." % [rate.currency_name,(sprintf "%.2f", notify.value)]
      send_mail(notify.email, subject, text, use_queues)
      notify.destroy
      count+=1
    end

    notifies=Notify.where("currency_code=? AND operation=? AND method=? AND value<=?", rate.from_currency, :sell, '>', rate.sell)
    text="%s продажа за %s руб." % [rate.currency_name,(sprintf "%.2f", rate.sell)]
    notifies.each do |notify|
      subject="Нотификация: продажа %s дороже %s руб." % [rate.currency_name,(sprintf "%.2f", notify.value)]
      send_mail(notify.email, subject, text, use_queues)
      notify.destroy
      count+=1
    end

    notifies=Notify.where("currency_code=? AND operation=? AND method=? AND value>=?", rate.from_currency, :sell, '<', rate.sell)
    text="%s продажа за %s руб." % [rate.currency_name,(sprintf "%.2f", rate.sell)]
    notifies.each do |notify|
      subject="Нотификация: продажа %s дешевле %s руб." % [rate.currency_name,(sprintf "%.2f", notify.value)]
      send_mail(notify.email, subject, text, use_queues)
      notify.destroy
      count+=1
    end
  end
  
  return count
end

def self.send_mail(email, subject, text, use_queues)
  if Rails.configuration.x.use_queues
    UserMailer.currency_notify_email(email, subject, text).deliver_later
  else
    UserMailer.currency_notify_email(email, subject, text).deliver_now
  end  
end
end