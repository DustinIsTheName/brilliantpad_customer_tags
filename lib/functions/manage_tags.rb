module ManageTags
	def self.setTags(customer)

		shopify_customer = ShopifyAPI::Customer.search(query: "email:#{customer.email}").first

		unless shopify_customer
			shopify_customer = ShopifyAPI::Customer.new
			shopify_customer.email = customer.email
			shopify_customer.tags = '';
		end

		old_tags = shopify_customer.tags

		if customer.weight
			shopify_customer.tags = shopify_customer.tags.remove_tag('weight:Under25').remove_tag('weight:Over25')
			shopify_customer.tags = shopify_customer.tags.add_tag('weight:'+customer.weight)
		end

		if customer.pads			
			shopify_customer.tags = shopify_customer.tags.remove_tag('pads:UsePads').remove_tag('pads:NotUsePads')
			shopify_customer.tags = shopify_customer.tags.add_tag('pads:'+customer.pads)
		end

		if customer.puppy
			shopify_customer.tags = shopify_customer.tags.remove_tag('puppy:YoungPuppy').remove_tag('puppy:NotPuppy')
			shopify_customer.tags = shopify_customer.tags.add_tag('puppy:'+customer.puppy)
		end

		if customer.nervous
			shopify_customer.tags = shopify_customer.tags.remove_tag('nervous:Nervous').remove_tag('nervous:NotNervous')
			shopify_customer.tags = shopify_customer.tags.add_tag('nervous:'+customer.nervous)
		end

		if customer.referral
			shopify_customer.tags = shopify_customer.tags.remove_tag('referral:Google').remove_tag('referral:Other Search').remove_tag('referral:Facebook').remove_tag('referral:SharkTank').remove_tag('referral:Instagram').remove_tag('referral:YouTube').remove_tag('referral:Friend').remove_tag('referral:Animal Radio').remove_tag('referral:Magazine').remove_tag('referral:Other').remove_tag('referral:')
			shopify_customer.tags = shopify_customer.tags.add_tag('referral:'+customer.referral)
		end

		if old_tags == shopify_customer.tags
			puts Colorize.cyan('tags are the same');
		else
			if shopify_customer.save
				print Colorize.green('saved customer tags')
				puts Colorize.orange(' ' << ShopifyAPI.credit_left.to_s)
			else
				puts Colorize.red('error saving tags')
			end
		end

	end
end