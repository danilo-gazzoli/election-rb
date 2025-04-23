class CreatePollworkers < ActiveRecord::Migration[7.1]
  def change
    create_table :pollworkers do |t|
      t.string :name
      t.string :login
      t.string :password
      t.integer :status, null: false, default: 0
      t.references :election, null: false, foreign_key: true

      t.timestamps
    end
  end
end
