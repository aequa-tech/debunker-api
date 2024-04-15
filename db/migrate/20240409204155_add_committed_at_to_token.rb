class AddCommittedAtToToken < ActiveRecord::Migration[7.0]
  def change
    add_column :tokens, :committed_at, :datetime
  end
end
