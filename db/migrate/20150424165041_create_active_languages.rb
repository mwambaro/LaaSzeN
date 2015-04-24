class CreateActiveLanguages < ActiveRecord::Migration
  def change
    create_table :active_languages do |t|
      t.string :language
      t.string :active
      t.string :default
      t.text :supported

      t.timestamps null: false
    end
  end
end
