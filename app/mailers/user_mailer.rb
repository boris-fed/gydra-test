class UserMailer < ActionMailer::Base
  default from: Rails.configuration.x.smtp_from_user
  
   def currency_notify_email(email, subject, text)
    mail(to: email, subject: subject) do |format|
      format.text {render text: text}
    end  
  end
end