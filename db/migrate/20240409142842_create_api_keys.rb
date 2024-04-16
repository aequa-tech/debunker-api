# frozen_string_literal: true

class CreateApiKeys < ActiveRecord::Migration[7.0]
  def change
    create_table :api_keys do |t|
      t.string :access_token
      t.string :secret_token
      t.datetime :expired_at
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
