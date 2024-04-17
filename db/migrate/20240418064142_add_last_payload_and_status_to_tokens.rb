class AddLastPayloadAndStatusToTokens < ActiveRecord::Migration[7.0]
  def change
    add_column :tokens, :last_payload, :text, default: ''
    add_column :tokens, :last_status, :integer, default: 0
    remove_column :tokens, :committed_at, :datetime
  end
end
