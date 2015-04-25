class CreatePhilosophies < ActiveRecord::Migration
  def change
    create_table :philosophies do |t|
      t.string :language
      t.string :theme
      t.string :part
      t.string :chapter
      t.string :topic
      t.string :subtopic
      t.text :content

      t.timestamps null: false
    end
  end
end
