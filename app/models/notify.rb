class Notify < ActiveRecord::Base
  self.table_name='notifies'
   
  validates :currency_code, presence: {message: "Необходимо указать валюту"}
  validates :operation, presence: {message: "Необходимо указать операцию"}
  validates :method, presence: {message: "Необходимо указать метод сравнения"}
  validates :email, presence: {message: "Необходимо указать e-mail"}
  validates :value, presence: {message: "Необходимо указать значение"}
  
  def set_defaults
    self.currency_code=840
    self.operation=:buy
    self.method='<'
    self.rub=0
    rate_usd=CurrencyRate.select('sell,buy').where(from_currency: 840).order(["last_update"]).last    
    if rate_usd!=nil
      if rate_usd.sell!=nil && rate_usd.buy!=nil
        self.rub=((rate_usd.sell+rate_usd.buy)/2).to_i
      end
    end
    self.kop='00'
  end
  
  def calc_value
    rub=0
    if self.rub!=nil 
      rub=self.rub
    end
    kop=0
    if self.kop!=nil 
      kop=self.kop.to_s.last(2).to_i
    end
    self.value=(rub.to_s << '.' << kop.to_s).to_f
  end
  
  def rub
    @rub
  end
  
  def rub=(value)
    @rub = value
  end
  
  def kop
    @kop
  end
  
  def kop=(value)
    @kop = value
  end
  
  def to_s
    return "currency=" << check_attribute_and_get(:currency_code).to_s << ", operation=" << check_attribute_and_get(:operation) << ", method=" << 
      check_attribute_and_get(:method) << ", value=" << check_attribute_and_get(:value).to_s << ", email=" << check_attribute_and_get(:email)
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