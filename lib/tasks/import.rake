task :import => :environment do
  ImportFromSpreadsheet.import
end