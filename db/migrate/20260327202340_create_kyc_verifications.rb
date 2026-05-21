class CreateKycVerifications < ActiveRecord::Migration[8.0]
  def change
    create_table :kyc_verifications, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.integer :document_type, null: false
      t.integer :status, null: false, default: 0
      t.text :notes
      t.uuid :reviewer_id
      t.datetime :reviewed_at
      t.timestamps
    end

    add_index :kyc_verifications, :user_id
    add_index :kyc_verifications, :reviewer_id
    add_index :kyc_verifications, :status
  end
end
