class CreateBooks < ActiveRecord::Migration
  def change
    create_table :books do |t|
      t.string :language
      t.string :theme
      t.string :author
      t.binary :content

      t.timestamps null: false
    end
  end
end
