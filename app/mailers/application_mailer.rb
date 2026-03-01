class ApplicationMailer < ActionMailer::Base
  default from: "from@example.com"
  layout "mailer"

  def self.with_merged(*param_sets)
    with(param_sets.compact.reduce({}) { |merged, params| merged.merge(params.to_h) })
  end
end
