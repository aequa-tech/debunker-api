class ChangeTokenColumns < ActiveRecord::Migration[7.0]
  def change
    rename_column :tokens, :retries, :perform_retries
    rename_column :tokens, :support_response_object, :response_json
    add_column :tokens, :callback_retries, :int, default: 0
    add_column :tokens, :perform_status, :int, default: 0
    add_column :tokens, :callback_status, :int, default: 0
    add_column :tokens, :payload_json, :text, default: ''
  end
end
