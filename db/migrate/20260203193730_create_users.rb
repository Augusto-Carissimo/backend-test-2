class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :department
      t.integer :max_capacity_allowed
      t.boolean :is_admin

      t.timestamps
    end
  end
end
