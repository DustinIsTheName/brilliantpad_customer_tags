class ImportFromSpreadsheet
	def self.import
		count = 0;

		CSV.foreach('https://cdn.shopify.com/s/files/1/2281/3847/files/sheet1_table_1.csv?13985435858544620720', :headers => true) do |row|
			count += 1
		  csv_customer = row.to_hash
		  # puts Colorize.green(csv_customer)

			customer = Customer.find_by_email(csv_customer["email"])

			unless customer
				customer = Customer.new
				customer.email = csv_customer["email"]
			end

			customer.weight = csv_customer["weight"]
			customer.pads = csv_customer["pads"]
			customer.puppy = csv_customer["puppy"]
			customer.nervous = csv_customer["nervous"]
			customer.referral = csv_customer["referral"]

			if customer.save
				ManageTags.setTags(customer)
				print Colorize.green('imported ' + customer.email)
				puts Colorize.orange(' ' + count.to_s)
			else
				puts Colorize.red('failed ' + customer.email)
			end

		end
	end
end