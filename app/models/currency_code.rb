class CurrencyCode < ActiveRecord::Base
  self.table_name = 'currency_codes'
  self.primary_key = 'code'
  
  def to_s
    return "code=#{code}, name=#{name}"
  end
end  