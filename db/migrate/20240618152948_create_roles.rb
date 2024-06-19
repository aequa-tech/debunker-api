class CreateRoles < ActiveRecord::Migration[7.0]
  def change
    create_table :roles do |t|
      t.string :name
      t.integer :role_type
      t.references :tier, null: false, foreign_key: true
      t.timestamps
    end

    Role.create(name: 'Admin', role_type: :admin, tier: Tier.first)
    Role.create(name: 'Basic', role_type: :user, tier: Tier.first)
  end
end
