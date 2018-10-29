class CreateUsersAndAccounts < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.string :email
      t.string :integration_type
      t.string :integration_id
      t.string :integration_login
      t.string :avatar_url
      t.string :access_token
      t.boolean :active

      t.timestamps
    end

    create_table :accounts do |t|
      t.string :name
      t.string :integration_type
      t.string :integration_id
      t.string :integration_account_type
      t.boolean :active

      t.timestamps
    end

    create_table :accounts_users, id: false do |t|
      t.belongs_to :account, index: true
      t.belongs_to :user, index: true
      t.index [:account_id, :user_id]

    end
  end
end
