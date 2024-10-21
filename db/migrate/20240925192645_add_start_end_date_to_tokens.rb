class AddStartEndDateToTokens < ActiveRecord::Migration[7.0]
  def change
    add_column :tokens, :request_started_at, :datetime
    add_column :tokens, :request_ended_at, :datetime
  end
end
