class CreateMottos < ActiveRecord::Migration[6.1]
  def change
    create_table :mottos do |t|
      t.string :language
      t.string :name
      t.binary :content

      t.timestamps null: false
    end
  end
end
