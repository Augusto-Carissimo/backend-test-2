class CreateReservations < ActiveRecord::Migration[8.0]
  def change
    create_table :reservations do |t|
      t.references :room, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.datetime :starts_at
      t.datetime :ends_at
      t.string :recurring
      t.date :recurring_until
      t.datetime :cancelled_at

      t.timestamps
    end
  end
end
