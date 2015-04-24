class CreateSlides < ActiveRecord::Migration
  def change
    create_table :slides do |t|
      t.string :language
      t.string :author
      t.string :theme
      t.string :topic
      t.binary :content

      t.timestamps null: false
    end
  end
end
