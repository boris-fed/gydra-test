class UserMailer < ActionMailer::Base
  default from: 'boris-fed@yandex.ru'
  
   def currency_notify_email(email, subject, text)
    mail(to: email, subject: subject) do |format|
      format.text {render text: text}
    end  
  end
end