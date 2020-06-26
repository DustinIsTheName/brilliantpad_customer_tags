class RechargeController < ApplicationController

  skip_before_filter :verify_authenticity_token
  before_filter :set_headers

  def get_customer
    customer = get_customer_function params["shopify_id"]

    render json: customer
  end

  def get_customer_function(shopify_id)
    url = URI("https://api.rechargeapps.com/customers?shopify_customer_id=#{shopify_id}")
    customer = recharge_http_request(url)["customers"].first
    # customer["addresses"] = get_addresses customer
    customer
  end

  def update_customer
    puts params

    url = URI("https://api.rechargeapps.com/customers/#{params["customer_id"]}")
    body = {
      first_name: params["firstName"],
      last_name: params["lastName"],
      billing_address1: params["address1"],
      billing_address2: params["address2"],
      billing_company: params["company"],
      billing_country: params["country"],
      billing_province: params["province"],
      billing_city: params["city"],
      billing_zip: params["zipcode"],
      email: params["email"],
      billing_phone: params["phone"]
    }
    customer = recharge_http_request(url, body, 'put')["customer"]

    render json: customer
  end

  def get_charges
    customer = get_customer_function params["shopify_customer_id"]

    time_now = Time.now
    time_then = Time.now + 6.month
    url = URI("https://api.rechargeapps.com/charges?customer_id=#{customer["id"]}&date_min=#{time_now.strftime("%Y-%m-%d")}&date_max=#{time_then.strftime("%Y-%m-%d")}")
    charges = recharge_http_request(url)["charges"]

    render json: charges
  end

  def skip_charge
    url = URI("https://api.rechargeapps.com/charges/#{params["charge_id"]}/skip")

    body = {
      subscription_id: params["subscription_id"]
    }
    charge = recharge_http_request(url, body, 'post')

    render json: charge
  end

  def unskip_charge
    url = URI("https://api.rechargeapps.com/charges/#{params["charge_id"]}/unskip")

    body = {
      subscription_id: params["subscription_id"]
    }
    charge = recharge_http_request(url, body, 'post')

    render json: charge
  end

  def get_subscriptions
    puts params

    if params["customer_id"]
      url = URI("https://api.rechargeapps.com/subscriptions?customer_id=#{params["customer_id"]}")
    elsif params["shopify_customer_id"]
      url = URI("https://api.rechargeapps.com/subscriptions?shopify_customer_id=#{params["shopify_customer_id"]}&status=ACTIVE")
    end

    subscriptions = recharge_http_request(url)["subscriptions"]
    
    products = {}
    recharge_products = {}

    sub_count = 0
    for subscription in subscriptions
      products[subscription["id"]] = ShopifyAPI::Product.find(subscription["shopify_product_id"])
      url = URI("https://api.rechargeapps.com/products?shopify_product_id=#{subscription["shopify_product_id"]}")

      recharge_products[subscription["id"]] = recharge_http_request(url)["products"].first
      subscriptions[sub_count]["address"] = get_address_function subscription["address_id"]

      sub_count = sub_count + 1
    end

    render json: {
      subscriptions: subscriptions,
      products: products,
      recharge_products: recharge_products
    }
  end

  def update_subscription
    puts params

    url = URI("https://api.rechargeapps.com/subscriptions/#{params["subscription"]}")
    body = {
      shopify_variant_id: params["updates"]["variant"],
      # quantity: params["updates"]["quantity"],
      order_interval_unit: params["updates"]["interval_unit"],
      order_interval_frequency: params["updates"]["delivery"],
      charge_interval_frequency: params["updates"]["delivery"],
      use_shopify_variant_defaults: true
    }
    subscription = recharge_http_request(url, body, 'put')["subscription"]

    url = URI("https://api.rechargeapps.com/subscriptions/#{params["subscription"]}/set_next_charge_date")
    body = {
      date: params["updates"]["charge"],
    }
    subscription_charge_date = recharge_http_request(url, body, 'post')["subscription"]

    puts subscription

    render json: {
      subscription: subscription,
      subscription_charge_date: subscription_charge_date
    }
  end

  def delay_subscription
    puts params
    url = URI("https://api.rechargeapps.com/subscriptions/#{params["subscription"]}")
    subscription = recharge_http_request(url)["subscription"]

    puts subscription

    date = DateTime.parse(subscription["next_charge_scheduled_at"])
    new_next_charge = (date + params["delay"].to_i.months).strftime("%Y-%m-%d")
    url = URI("https://api.rechargeapps.com/subscriptions/#{params["subscription"]}/set_next_charge_date")
    body = {
      date: new_next_charge,
    }
    subscription_charge_date = recharge_http_request(url, body, 'post')["subscription"]

    render json: subscription_charge_date
  end

  def cancel_subscription
    url = URI("https://api.rechargeapps.com/subscriptions/#{params["subscription"]}/cancel")

    body = {
      cancellation_reason: params["reason"],
      cancellation_reason_comments: params["additional_comments"]
    }
    subscription = recharge_http_request(url, body, 'post')

    render json: subscription
  end

  def get_orders
    puts params
    customer = get_customer_function params["shopify_customer_id"]

    url = URI("https://api.rechargeapps.com/orders?customer_id=#{customer["id"]}")
    orders = recharge_http_request(url)["orders"]

    render json: orders
  end

  def get_payment_source
    puts params
    customer = get_customer_function params["shopify_customer_id"]

    url = URI("https://api.rechargeapps.com/customers/#{customer["id"]}/payment_sources")
    payment_source = recharge_http_request(url)["payment_sources"]

    render json: payment_source
  end

  def update_billing
    puts params
    Stripe.api_key = ENV["STRIPE_SECRET_KEY"]
    # cus_BCsVb8jUmteiwx

    customer = get_customer_function params["shopify_customer_id"]

    begin
      expiration = params["exp-date"].split('/')
      token = Stripe::Token.create({
        card: {
          number: params["cardnumber"],
          exp_month: expiration[0],
          exp_year: expiration[1],
          cvc: params["cvc"]
        }
      })
      if customer["stripe_customer_token"]
        stripe_customer = Stripe::Customer.update(
          customer["stripe_customer_token"],
          {source: token.id}
        )
      else
        stripe_customer = Stripe::Customer.create(
          :description => "Customer: #{params["name"]}",
          :source => token.id
        )
      end

      url = URI("https://api.rechargeapps.com/customers/#{customer["id"]}")
      body = {
        stripe_customer_token: stripe_customer["id"]
      }
      customer = recharge_http_request(url, body, 'put')

      render json: customer
    rescue => e
      render json: {
        error: e
      }
    end
  end

  def add_discount
    puts params
    url = URI("https://api.rechargeapps.com/discounts?discount_code=#{params["discount"]}")
    discount = recharge_http_request(url)["discounts"].first

    if discount
      url = URI("https://api.rechargeapps.com/addresses/#{params["address_id"]}/apply_discount")
      body = {
        "discount_code": params["discount"]
      }
      address = recharge_http_request(url, body, 'post')

      render json: {
        discount: discount,
        address: address
      }
    else
      render json: discount
    end
  end

  def remove_discount
    puts params
    url = URI("https://api.rechargeapps.com/addresses/#{params["address_id"]}/remove_discount")
    address = recharge_http_request(url, {}, 'post')["address"]

    render json: address
  end

  def get_address
    address = get_address_function params["address_id"]
    render json: address
  end

  def get_address_function(address_id)
    puts address_id
    url = URI("https://api.rechargeapps.com/addresses/#{address_id}")
    address = recharge_http_request(url)["address"]

    if address["discount_id"]
      address["discount"] = get_discount address["discount_id"]
    else
      address["discount"] = nil
    end

    address
  end

  def update_address
    url = URI("https://api.rechargeapps.com/addresses/#{params["address_id"]}")
    body = {
      first_name: params["firstName"],
      last_name: params["lastName"],
      address1: params["address1"],
      address2: params["address2"],
      company: params["company"],
      country: params["country"],
      province: params["province"],
      city: params["city"],
      zip: params["zipcode"],
      email: params["email"],
      phone: params["phone"]
    }
    address = recharge_http_request(url, body, 'put')

    render json: address
  end

  def get_addresses(customer)
    url = URI("https://api.rechargeapps.com/customers/#{customer["id"]}/addresses")
    addresses = recharge_http_request(url)["addresses"]

    for i in 0..(addresses.length - 1)
      a = addresses[i]
      if a["discount_id"]
        a["discount"] = get_discount a["discount_id"]
        puts Colorize.green "discount_id"
      else
        a["discount"] = nil
        puts Colorize.green "none"
      end

      puts a["discount"]

      addresses[i] = a
    end

    addresses
  end

  def get_discount(discount_id)
    url = URI("https://api.rechargeapps.com/discounts/#{discount_id}")
    recharge_http_request(url)["discount"]
  end

  private

    def set_headers
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Request-Method'] = '*'
    end

    def recharge_http_request(url, body = nil, type = nil)
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

      request["x-recharge-access-token"] = ENV['RECHARGE_API_KEY']
      request["content-type"] = 'application/json'

      if body
        request.body = body.to_json
      end

      response = http.request(request)

      # puts Colorize.yellow(response.body)
      puts Colorize.yellow(response.code)

      JSON.parse response.read_body
    end

end