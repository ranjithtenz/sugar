class CreateCategories < ActiveRecord::Migration
    def self.up
        create_table :categories do |t|
            t.string :name, :description
            t.integer :position, :discussions_count, :default => 0, :null => false
            t.timestamps
        end
    end

    def self.down
        drop_table :categories
    end
end
