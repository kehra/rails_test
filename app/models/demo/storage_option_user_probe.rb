class Demo::StorageOptionUserProbe < User
  has_one_attached :service_avatar, service: :local, dependent: :purge_later do |attachable|
    attachable.variant :thumb, resize_to_limit: [ 1, 1 ], process: :later
  end

  has_many_attached :service_documents, service: :local, dependent: :purge_later
end
