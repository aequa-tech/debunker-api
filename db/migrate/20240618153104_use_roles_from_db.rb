class UseRolesFromDb < ActiveRecord::Migration[7.0]
  def change
    add_reference :users, :role, null: false, foreign_key: true, default: Role.find_by(role_type: :user).id
    User.where(role: 1).update_all(role_id: Role.find_by(role_type: :admin).id)
    User.where(role: 0).update_all(role_id: Role.find_by(role_type: :user).id)
    remove_column :users, :role, :integer
  end
end
