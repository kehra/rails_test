class ExecutionContextProbe
  def self.capture(user:, request_id:)
    snapshots = {}

    Rails.application.executor.wrap do
      ActiveSupport::ExecutionContext.set(request_id:) do
        snapshots[:inside_set] = ActiveSupport::ExecutionContext.to_h.dup
        snapshots[:inside_executor] = ActiveSupport::ExecutionContext.to_h.dup
        Current.set(user:, request_id:) do
          snapshots[:inside_current] = {
            execution_context: ActiveSupport::ExecutionContext.to_h.dup,
            current_user_id: Current.user&.id,
            current_request_id: Current.request_id
          }
        end
      end
    end

    snapshots[:after] = ActiveSupport::ExecutionContext.to_h.dup
    snapshots
  end
end
