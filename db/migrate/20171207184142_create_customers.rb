class CreateCustomers < ActiveRecord::Migration
  def change
    create_table :customers do |t|

    	t.string :email

    	t.string :weight
    	t.string :pads
    	t.string :puppy
    	t.string :nervous
    	t.string :referral

      t.timestamps null: false
    end
  end
end
