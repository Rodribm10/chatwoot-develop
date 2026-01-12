class Captain::Reminders::TriggerJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform
    Captain::Reminder.due.find_each(batch_size: 100) do |reminder|
      Captain::Reminders::Processor.new(reminder).perform
    end
  end
end
