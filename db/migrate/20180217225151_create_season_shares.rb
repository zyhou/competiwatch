class CreateSeasonShares < ActiveRecord::Migration[5.1]
  def change
    create_table :season_shares do |t|
      t.integer :season, null: false
      t.integer :oauth_account_id, null: false
      t.datetime :created_at, null: false
    end
    add_index :season_shares, [:oauth_account_id, :season], unique: true
  end
end
