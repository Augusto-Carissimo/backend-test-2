class CreateRooms < ActiveRecord::Migration[8.0]
  def change
    create_table :rooms do |t|
      t.string :name
      t.integer :capacity
      t.boolean :has_projector
      t.boolean :has_video_conference
      t.integer :floor

      t.timestamps
    end
  end
end
