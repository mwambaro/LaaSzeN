class CreateAnnouncements < ActiveRecord::Migration[6.1]
  def change
    create_table :announcements do |t|
      t.string :language
      t.string :name
      t.binary :content

      t.timestamps null: false
    end
  end
end
