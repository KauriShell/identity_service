class CreateServiceTenants < ActiveRecord::Migration[8.0]
  def change
    create_table :service_tenants, id: :uuid do |t|
      t.string :name, null: false
      t.string :token_digest, null: false
      t.text :description
      t.boolean :active, null: false, default: true
      t.timestamps
    end

    add_index :service_tenants, :name, unique: true
    add_index :service_tenants, :token_digest, unique: true
  end
end
