class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :async

  validate :email_is_unique, on: :create
  after_create :create_account

  #def confirmation_required?
  #  false
  #end

  #def send_devise_notification(notification, one, two)
  #  byebug
  #  devise_mailer.send(notification, self).deliver
  #end

  #def send_confirmation_instructions
  #  unless @raw_confirmation_token
  #    generate_confirmation_token!
  #  end
#
#    opts = pending_reconfirmation? ? { to: unconfirmed_email } : { }
#    send_devise_notification(:confirmation_instructions, opts)
#  end

def send_devise_notification(notification, *args)
  devise_mailer.send(notification, self, *args).deliver_later
end

  private

  #Email should be unique in Account model
  def email_is_unique
    #Do not validate email if errors for email already exist
    return false unless self.errors[:email].empty?
    unless Account.find_by_email(email).nil?
      errors.add(:email, " is already used")
    end
  end

  def create_account
    account = Account.new(:email => email)
    account.save!
  end

end
