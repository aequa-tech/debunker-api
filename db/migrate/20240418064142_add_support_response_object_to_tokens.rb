class AddSupportResponseObjectAndSuccesssToTokens < ActiveRecord::Migration[7.0]
  def change
    add_column :tokens, :support_response_object, :text, default: ''
    add_column :tokens, :success, :boolen, default: false
    remove_column :tokens, :committed_at, :datetime
  end
end
