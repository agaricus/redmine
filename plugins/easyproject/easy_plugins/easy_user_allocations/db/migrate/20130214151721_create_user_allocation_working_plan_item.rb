class CreateUserAllocationWorkingPlanItem < ActiveRecord::Migration
  def up
    create_table :easy_user_allocation_working_plan_items do |t|
      t.references :issue
      t.references :user

      t.integer :d_year, :null => false
      t.integer :d_week, :null => false

      t.text    :comment

      t.timestamps
    end

  end

  def down
    drop_table :easy_user_allocation_working_plan_items
  end
end
