class SubscriptionsController < ApplicationController

  before_action :authenticate_user!

  def index
    @account = Account.find_by_email(current_user.email)
  end

  def new
    @plans = Plan.all
  end

  def create

    # Get the credit card details submitted by the form
    token           = params[:stripeToken]
    plan            = params[:plan][:stripe_id]
    email           = current_user.email
    current_account = Account.find_by_email(current_user.email)
    customer_id     = current_account.customer_id
    current_plan = current_account.stripe_plan_id

    if customer_id.nil?
      #New customer - Create a customer
      @customer = Stripe::Customer.create(
        :source => token,
        :plan   => plan,
        :email  => email
      )

      subscriptions     = @customer.subscriptions
      @subscribed_plan  = subscriptions.data.find{ |o| o.plan.id == plan }
      
    else
      #Customer exists - get customer from stripe
      @customer         = Stripe::Customer.retrieve(customer_id)
      @subscribed_plan  = create_or_update_subscription(@customer, current_plan, plan)

    end

    #Get current period end - This is a unix timestamp
    current_period_end = @subscribed_plan.current_period_end
    #Convert to datetime
    active_until = Time.at(current_period_end).to_datetime

    save_account_details(current_account, plan, @customer.id, active_until)

    redirect_to :root, :notice => "Successfully subscribed to a plan"

  rescue => e
    redirect_to :back, :flash => { :error => e.message }
  end

  def edit

    @account = Account.find(params[:id])
    @plans = Plan.all

  end



  def save_account_details(account, plan, customer_id, active_until)
    #Update account with the details
    account.stripe_plan_id  = plan
    account.customer_id     = customer_id
    account.active_until    = active_until
    account.save!
  end


  def create_or_update_subscription(customer, current_plan, new_plan)

    subscriptions = customer.subscriptions
    #Get current subscription
    current_subscription = subscriptions.data.find { |o| o.plan.id == current_plan }

    if current_subscription.blank?
      #No current subscription
      #Maybe the customer unsubscribed previously or maybe the card was declined
      #So, create a new subscription to existing customer
      subscription = customer.subscriptions.create( {:plan => new_plan} )
    else
      #Existing subscirption found so it must be an upgrade or downgrade
      #So update existing subscription with the new plan
      current_subscription.plan = new_plan
      subscription = current_subscription.save
    end

    return subscription

  end


end
