class AddSupportResponseObjectToTokens < ActiveRecord::Migration[7.0]
  def change
    add_column :tokens, :support_response_object, :text, default: ''
    remove_column :tokens, :committed_at, :datetime
  end
end
