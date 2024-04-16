class AddRetriesToToken < ActiveRecord::Migration[7.0]
  def change
    add_column :tokens, :retries, :integer, default: 0
  end
end
