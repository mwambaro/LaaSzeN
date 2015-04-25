class CreateBooks < ActiveRecord::Migration
  def change
    create_table :books do |t|
      t.string :language
      t.string :author
      t.string :theme
      t.binary :content

      t.timestamps null: false
    end
  end
end
