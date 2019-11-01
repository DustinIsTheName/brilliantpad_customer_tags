class PreOrderController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:tag_order]

  def tag_order
    puts params

    order = ShopifyAPI::Order.find params["id"]

    pre_order = false
    for item in params["line_items"]
      if item["properties"]
        for prop in item["properties"]
          if prop["name"] == "pre-order"
            pre_order = true
          end
        end
      end
    end

    if pre_order
      if order.tags.empty?
        order.tags = "pre-order"
      else
        order.tags << ", pre-order"
      end
    end

    if order.save
      puts Colorize.green('saved')
    else
      puts Colorize.red('saved')
    end

    render nothing: true, status: 200
  end
end