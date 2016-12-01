class NotifyController < ApplicationController
  def create
    begin
      count=Notify.where(email: params[:notify][:email]).count(:email)
      if count>=CommonConst::MAX_NOTIFY_PER_EMAIL
        raise 'Можно добавлять не более 10 нотификаций на один адрес e-mail'
      end  
    
      @notify=Notify.new(params[:notify].permit(:currency_code, :operation, :method, :value, :email, :rub, :kop)) do |n|
        n.calc_value
      end
      
      if @notify.save
        @notify=Notify.new do |n|
          n.set_defaults
        end  
        @notify_create_success=1
      end  
    rescue => e
      logger.error(e.to_s)
      @notify=Notify.new do |n|
        n.set_defaults
        n.errors.add(:base, "Ошибка добавления нотификации: " << e.message)
      end
    end
    
    respond_to do |format|
      format.js
    end
  end
  
  def index
    @notifies=Notify.joins("LEFT OUTER JOIN currency_codes ON notifies.currency_code=currency_codes.code")
      .select("notifies.*,currency_codes.name as currency_name")
      .where(email: params[:search_email])
    respond_to do |format|
      format.js
    end
  end
  
  def remove
    notify = Notify.find(params[:remove_notify_id])
    notify.destroy
    
    @notifies=Notify.joins("LEFT OUTER JOIN currency_codes ON notifies.currency_code=currency_codes.code")
      .select("notifies.*,currency_codes.name as currency_name")
      .where(email: params[:search_email])

    respond_to do |format|
      format.js
    end
  end
end  