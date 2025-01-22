RSpec.configure do |config| 
  config.before(:suit) do 
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.arround(:each) do 
    DatabaseCleaner.cleaning do 
      exemple.run
    end
  end
end
