class AddStripePlanIdToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :stripe_plan_id, :string
  end
end
