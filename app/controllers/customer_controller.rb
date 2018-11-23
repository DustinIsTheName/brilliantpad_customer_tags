class CustomerController < ApplicationController

	skip_before_filter :verify_authenticity_token
	before_filter :set_headers

	def save
		puts Colorize.magenta(params)

		customer = Customer.find_by_email(params["email"])

		unless customer
			customer = Customer.new
			customer.email = params["email"]
		end

		for answer in params["answers"]
			case answer
			when 'Under25', 'Over25'
				customer.weight = answer
			when 'UsePads', 'NotUsePads'
				customer.pads = answer
			when 'YoungPuppy', 'NotPuppy'
				customer.puppy = answer
			when 'Nervous', 'NotNervous'
				customer.nervous = answer
			else
				customer.referral = answer
			end
		end

		if customer.save
			ManageTags.setTags(customer)
			render json: customer
		else
			render json: customer
		end
	end

	def get
		puts Colorize.magenta(params)

		customer = Customer.find_by_email(params["email"])

		if customer
			render json: customer
		else
			render json: {error: "No such user; check the submitted email address"}, status: 404
		end
	end

  def get_order
    puts Colorize.magenta(params)

    order = ShopifyAPI::Order.find(:all, params: {name: params["order_number"], status: 'any'})&.first

    render json: order
  end

	private

		def set_headers
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Request-Method'] = '*'
    end

end
