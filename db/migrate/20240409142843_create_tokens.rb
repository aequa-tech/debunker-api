# frozen_string_literal: true

class CreateTokens < ActiveRecord::Migration[7.0]
  def change
    create_table :tokens do |t|
      t.string :value
      t.references :api_key, null: false, foreign_key: true
      t.integer :retries, default: 0
      t.string :used_on, default: nil
      t.datetime :committed_at
      t.timestamps
    end
  end
end
