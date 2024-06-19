class CreateTiers < ActiveRecord::Migration[7.0]
  def change
    create_table :tiers do |t|
      t.string :name
      t.integer :tokens_rate
      t.integer :reload_rate_amount
      t.string :reload_rate_unit
      t.timestamps
    end

    # Basic Tier - 10 tokens, reload every 1 month
    Tier.create(name: 'Free', tokens_rate: 10, reload_rate_amount: 1, reload_rate_unit: 'month')

    # Add reloaded_at column to api_keys
    add_column :api_keys, :reloaded_at, :date
    ApiKey.all.each do |api_key|
      api_key.update_columns(reloaded_at: api_key.created_at.to_date)
    end
  end
end
