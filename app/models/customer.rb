class Customer < ActiveRecord::Base

	validates :email, uniqueness: true

end
