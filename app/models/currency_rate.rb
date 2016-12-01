class CurrencyRate < ActiveRecord::Base
  self.table_name = 'currency_rates'
 
  def calc_details
    self.buy||=0
    self.sell||=0
    self.spread=self.sell-self.buy
    self.spread_percentage=self.sell/self.buy - 1

    prev_rate=nil
    sell=0
    sell_delta=0
    sell_count=0
    buy=0
    buy_count=0
    buy_delta=0
    average_delta=0
    rates=CurrencyRate.where("last_update > ? and from_currency=?", self.last_update.to_date, self.from_currency).order(:last_update)
    rates.each do |rate|
      if prev_rate!=nil
        sell_delta+=rate.sell-prev_rate.sell
        sell_count+=1
        buy_delta+=rate.buy-prev_rate.buy
        buy_count+=1
      end
      sell+=rate.sell
      buy+=rate.buy
      prev_rate=rate
    end
    
    if sell_count>0 && buy_count>0
      average_delta=(sell_delta/sell_count+buy_delta/buy_count)/2
    end
    
    self.average=(sell/(sell_count+1)+buy/(buy_count+1))/2
    self.forecast=(self.sell+self.buy)/2+average_delta
    
    if self.respond_to?(:from_currency_name)==false
      currency_code=CurrencyCode.where(code: self.from_currency).first
      if currency_code!=nil
        @from_currency_name=currency_code.name
      end  
    end
  end

  def average
    @average
  end
  
  def average=(value)
    @average = value
  end
  
  def spread
    @spread
  end
  
  def spread=(value)
    @spread = value
  end
  
  def spread_percentage
    @spread_percentage
  end
  
  def spread_percentage=(value)
    @spread_percentage = value
  end
  
  def forecast
    @forecast
  end
  
  def forecast=(value)
    @forecast = value
  end

  def currency_name
    if self.respond_to?(:from_currency_name)==false
      if self.instance_variable_defined?(:@from_currency_name)
        return @from_currency_name
      else
        return self.from_currency
      end
    else
      return self.from_currency_name
    end
  end
  
  def to_s
    return check_attribute_and_get(:last_update).to_s << ": from " <<
        check_attribute_and_get(:from_currency).to_s << "/" << self.currency_name << " to " <<
        check_attribute_and_get(:to_currency).to_s << ": buy=" << check_attribute_and_get(:buy).to_s << ", sell=" <<
        check_attribute_and_get(:sell).to_s << ", average=" << check_attribute_and_get(:average).to_s << " ,spread=" << 
        check_attribute_and_get(:spread).to_s << ", spread(%)=" << check_attribute_and_get(:spread_percentage).to_s <<
        ", forecast=" << check_attribute_and_get(:forecast).to_s
  end
  
  private
  def check_attribute_and_get(attr_name)
    if self.respond_to?(attr_name)==false
      return ''
    else
      if self[attr_name]==nil
        return ''
      else  
        return self[attr_name]
      end
    end 
  end
end
