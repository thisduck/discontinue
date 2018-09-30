class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.string :email
      t.string :github_auth_id
      t.string :github_login
      t.string :github_avatar_url
      t.string :access_token

      t.timestamps
    end
  end
end
