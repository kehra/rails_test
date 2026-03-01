module Teamhub
  module ParameterizedMailerChain
    def with(params)
      merged = instance_variable_get(:@params).merge(params.to_h)
      self.class.new(instance_variable_get(:@mailer), merged)
    end
  end
end

ActionMailer::Parameterized::Mailer.prepend(Teamhub::ParameterizedMailerChain)
