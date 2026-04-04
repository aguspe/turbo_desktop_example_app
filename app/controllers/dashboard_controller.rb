class DashboardController < ApplicationController
  def index
    @total_tasks = Task.count
    @completed_tasks = Task.where(completed: true).count
    @pending_tasks = Task.where(completed: false).count
    @recent_tasks = Task.order(created_at: :desc).limit(5)
  end
end
