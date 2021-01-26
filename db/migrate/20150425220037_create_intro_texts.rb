class CreateIntroTexts < ActiveRecord::Migration[6.1]
  def change
    create_table :intro_texts do |t|
      t.string :language
      t.binary :content

      t.timestamps null: false
    end
  end
end
