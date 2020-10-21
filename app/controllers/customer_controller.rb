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

  def save_order
    puts Colorize.magenta(params)
    puts Colorize.magenta(params["line_items"].first["properties"])

    customer = Customer.find_by_email(params["email"])

    unless customer
      customer = Customer.new
      customer.email = params["email"]
    end

    for item in params["line_items"]
      properties = params["line_items"].first["properties"]

      if properties
        for property in properties
          case property["name"]
          when 'option-weight'
            puts Colorize.cyan('option-weight')
            if property["value"] == 'Over 25 lbs'
              customer.weight = 'Over25'
              puts Colorize.green('Over25')
            else
              customer.weight = 'Under25'
              puts Colorize.green('Over25')
            end
          when 'option-use-pads'
            puts Colorize.cyan('option-use-pads')
            if property["value"] == 'Yes'
              customer.pads = 'UsePads'
              puts Colorize.green('UsePads')
            else
              customer.pads = 'NotUsePads'
              puts Colorize.green('NotUsePads')
            end
          when 'option-puppy'
            puts Colorize.cyan('option-puppy')
            if property["value"] == 'Yes'
              customer.puppy = 'YoungPuppy'
              puts Colorize.green('YoungPuppy')
            else
              customer.puppy = 'NotPuppy'
              puts Colorize.green('NotPuppy')
            end
          end
        end
      end
    end

    if customer.save
      ManageTags.setTags(customer)
    else
      puts customer.errors
    end

    render json: nil
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

  def earn_points
    puts Colorize.magenta(params)

    customer = ShopifyAPI::Customer.search(query: "email:#{params["email"]}").first

    if customer
      unless customer.tags.include? "filled_in_dog_profile"

        activity_body = {
          "name" => "dog_profile",
          "customer_id" => customer.id.to_s,
          "customer_email" => customer.email,
          "guest" => false
        }
        uri = URI.parse("https://api.loyaltylion.com/v2/activities")

        response = http_request(uri, activity_body, 'post')

        customer.tags = customer.tags.add_tag "filled_in_dog_profile"

        customer.save

      end
    end

    puts response

    if response
      render json: {success: true}
    else
      render json: {success: false}
    end
  end

  def earn_points_typeform
    
  end

  def refresh_token
    render json: params
  end

	private

		def set_headers
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Request-Method'] = '*'
    end

    def http_request(url, body = nil, type = nil)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      if type == "delete"
        request = Net::HTTP::Delete.new(url)
      elsif type == "post"
        request = Net::HTTP::Post.new(url)
      elsif type == "put"
        request = Net::HTTP::Put.new(url)
      elsif type == "get"
        request = Net::HTTP::Get.new(url)
      else
        request = Net::HTTP::Get.new(url)
      end

      request.basic_auth(ENV["LOYALTYLION_TOKEN"], ENV["LOYALTYLION_SECRET"])
      request.content_type = "application/json"
      req_options = {
        use_ssl: url.scheme == "https",
      }
      # request["content-type"] = 'application/json'

      if body
        request.body = body.to_json
      end

      response = http.request(request)

      puts Colorize.yellow(request.body)
      puts Colorize.yellow(response.code)

      response.read_body
    end

end
