class CreateParties < ActiveRecord::Migration[7.1]
  def change
    create_table :parties do |t|
      t.string :name
      t.string :abbreviation
      t.integer :party_number
      t.text :description
      t.references :election, null: false, foreign_key: true

      t.timestamps
    end
  end
end
