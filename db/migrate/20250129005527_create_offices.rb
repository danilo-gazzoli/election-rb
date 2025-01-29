class CreateOffices < ActiveRecord::Migration[7.1]
  def change
    create_table :offices do |t|
      t.string :name
      t.integer :num_of_seats
      t.boolean :needs_vice
      t.references :election, null: false, foreign_key: true

      t.timestamps
    end
  end
end
