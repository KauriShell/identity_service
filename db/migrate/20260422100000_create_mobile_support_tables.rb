class CreateMobileSupportTables < ActiveRecord::Migration[8.0]
  def change
    create_table :otp_codes, id: :uuid do |t|
      t.string :phone_number, null: false
      t.string :code_digest, null: false
      t.datetime :expires_at, null: false
      t.datetime :consumed_at
      t.integer :attempts_count, null: false, default: 0
      t.datetime :last_sent_at, null: false
      t.integer :send_count, null: false, default: 1
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
    add_index :otp_codes, :phone_number
    add_index :otp_codes, :expires_at

    create_table :notifications, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.string :notification_type, null: false
      t.string :title, null: false
      t.text :body
      t.boolean :read, null: false, default: false
      t.datetime :read_at
      t.string :related_resource_type
      t.uuid :related_resource_id
      t.string :deep_link
      t.jsonb :metadata, null: false, default: {}
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
    add_index :notifications, :user_id
    add_index :notifications, %i[user_id read]
    add_index :notifications, :notification_type

    create_table :payout_accounts, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.string :account_type, null: false
      t.string :phone_number
      t.string :bank_code
      t.string :bank_name
      t.string :account_name
      t.string :account_number
      t.boolean :primary, null: false, default: false
      t.boolean :active, null: false, default: true
      t.jsonb :metadata, null: false, default: {}
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
    add_index :payout_accounts, :user_id
    add_index :payout_accounts, %i[user_id primary]

    create_table :devices, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.string :platform, null: false
      t.string :push_token, null: false
      t.string :device_name
      t.string :app_version
      t.string :locale
      t.datetime :last_seen_at
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end
    add_index :devices, :user_id
    add_index :devices, :push_token, unique: true
  end
end
