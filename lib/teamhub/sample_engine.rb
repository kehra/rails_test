module Teamhub
  class SampleEngine < Rails::Engine
    engine_name "teamhub_sample_engine"
    isolate_namespace Teamhub

    paths["app/controllers"] << root.join("lib/teamhub/sample_engine/app/controllers")
    paths["config/locales"] << root.join("lib/teamhub/sample_engine/config/locales")
    paths["app/assets"] << root.join("lib/teamhub/sample_engine/app/assets")
    paths["config/routes.rb"] = root.join("lib/teamhub/sample_engine/config/routes.rb")

    routes.prepend do
      get "/prefixed", to: proc { [ 200, { "Content-Type" => "text/plain" }, [ "prefixed" ] ] }
    end

    routes.append do
      get "/appended", to: proc { [ 200, { "Content-Type" => "text/plain" }, [ "appended" ] ] }
    end

    initializer "teamhub.sample_engine.assets" do |app|
      app.config.assets.paths << root.join("lib/teamhub/sample_engine/app/assets/stylesheets").to_s
      app.config.assets.precompile += %w[teamhub/sample_engine.css]
    end
  end
end
