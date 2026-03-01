module Api
  class MetalPingsController < ActionController::Metal
    include ActionController::Head

    def show
      self.status = 200
      self.location = "/docs/about"
      self.content_type = "application/json"
      headers["X-Metal-Temp"] = "transient"
      deleted_header = headers["X-Metal-Temp"]
      headers.delete("X-Metal-Temp")
      headers["X-Metal-Ping"] = "true"

      payload = {
        ok: true,
        via: "metal",
        status: status,
        location: location,
        content_type: content_type,
        media_type: media_type,
        header: headers["X-Metal-Ping"],
        deleted_header: deleted_header,
        temp_header_present: headers.key?("X-Metal-Temp")
      }
      self.response_body = [ payload.to_json ]
      payload[:response_body_class] = response_body.class.name
      payload[:response_body_length] = response_body.length
      self.response_body = [ payload.to_json ]
    end
  end
end
