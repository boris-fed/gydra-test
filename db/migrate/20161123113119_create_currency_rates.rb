class CreateCurrencyRates < ActiveRecord::Migration
  def change
    create_table :currency_rates do |t|
      t.integer :from_currency, :null=>true
      t.integer :to_currency, :null=>true
      t.float :buy, :null=>true
      t.float :sell, :null=>true
      t.datetime :last_update, :null=>true
    end
    
    create_table :currency_codes, :id => false do |t|
      t.integer :code, primary_key: true
      t.string :name
    end
    
    CurrencyCode.create!(code: 840, name: 'USD')
    CurrencyCode.create!(code: 978, name: 'EUR')
    CurrencyCode.create!(code: 643, name: 'RUR')
    
    create_table :notifies do |t|
      t.integer :currency_code
      t.string :operation
      t.string :method
      t.float :value
      t.string :email
    end
  end
end
