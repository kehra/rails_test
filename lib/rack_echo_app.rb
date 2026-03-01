require "json"

class RackEchoApp
  def self.call(env)
    request = Rack::Request.new(env)
    [ 200, { "Content-Type" => "application/json" }, [ { path: request.path, method: request.request_method }.to_json ] ]
  end
end
