class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :async

  validate :email_is_unique, on: :create
  after_create :create_account

  #Override devise method to integrate with devise-async with user token
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

  #Create an account everytime a user registers
  def create_account
    account = Account.new(:email => email)
    account.save!
  end

end
