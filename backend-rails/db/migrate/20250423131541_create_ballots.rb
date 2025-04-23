class CreateBallots < ActiveRecord::Migration[7.1]
  def change
    create_table :ballots do |t|
      t.string :username
      t.string :password
      t.integer :status, null: false, default: 0
      t.references :election, null: false, foreign_key: true
      t.references :pollworker, null: false, foreign_key: true

      t.timestamps
    end
  end
end
