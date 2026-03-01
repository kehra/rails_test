module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
      logger.add_tags current_user.name
    end

    def disconnect
      Rails.event.notify("teamhub.cable.disconnect", user_id: current_user&.id)
    end

    private

    def find_verified_user
      user = User.find_by(id: cookies.signed[:cable_user_id])
      return user if user

      reject_unauthorized_connection
    end
  end
end
