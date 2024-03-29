class OrderSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :id, :description, :order_status,
    :start_order, :end_order, :price, :paid, :images, :urgency,
    :professional_photo, :rate, :order_wirecard_own_id, :order_wirecard_id,
    :payment_wirecard_id, :hora_inicio, :hora_fim, :user_rate, :user_photo

  has_one :category
  has_one :professional_order
  has_one :user
  has_one :address
  has_one :budget

  def images
    urls = []
    
    object.images.each do |image|
      urls << rails_blob_path(image, only_path: true)
    end
    
    urls
  end

  def professional_photo
    if object.professional_order && object.professional_order.user_profile_photo
      rails_blob_path(object.professional_order.user_profile_photo.photo, only_path: true)
    else
      nil
    end
  end

  def user_photo
    if object.user && object.user.user_profile_photo
      rails_blob_path(object.user.user_profile_photo.photo, only_path: true)
    else
      nil
    end
  end
end
