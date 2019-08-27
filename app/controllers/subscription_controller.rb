class SubscriptionController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:current, :upgrade]
  before_filter :set_headers

  def current
    puts params

    url = URI("https://api.rechargeapps.com/customers/?hash=#{params['sub_id']}")
    recharge_customer = recharge_http_request url

    sub_url = URI("https://api.rechargeapps.com/subscriptions/?customer_id=#{recharge_customer["customers"].first["id"]}")
    recharge_subscription = recharge_http_request(sub_url)

    render json: recharge_subscription.first
  end

  def upgrade
    puts Colorize.magenta params

    new_subscription = params["new_subscription"]

    old_sub_params = {
      cancellation_reason: 'Upgrade'
    }

    url = URI("https://api.rechargeapps.com/subscriptions/#{params["old_subscription"]}/cancel")
    recharge_customer = recharge_http_request(url, old_sub_params, 'post')

    new_customer_params = {
      address_id: new_subscription["address_id"],
      next_charge_scheduled_at: new_subscription["next_charge_scheduled_at"],
      shopify_variant_id: new_subscription["variant_id"],
      quantity: 1,
      order_interval_unit: new_subscription["order_interval_unit"],
      order_interval_frequency: new_subscription["order_interval_frequency"],
      charge_interval_frequency: new_subscription["order_interval_frequency"]
    }

    url = URI("https://api.rechargeapps.com/subscriptions")
    recharge_customer = recharge_http_request(url, new_customer_params, 'post')

    render json: recharge_customer
  end

  def test
    puts "TESTING"

    render json: {testing: true}
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

      puts Colorize.yellow(request.body)
      puts Colorize.yellow(response.code)

      JSON.parse response.read_body
    end

end