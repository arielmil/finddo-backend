class AddProfessionalPreferenceToOrders < ActiveRecord::Migration[6.0]
  def change
    add_reference :orders, :selected_professional, null: true, default: false, foreign_key: { to_table: 'users' }
  end
end