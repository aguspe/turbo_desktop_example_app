class TasksController < ApplicationController
  before_action :set_task, only: %i[show edit update destroy]

  def index
    @tasks = Task.order(created_at: :desc)
  end

  def show
  end

  # GET /tasks/new — opens in a modal window via path configuration
  # The desktop shell sees that this URL matches "/new$" and opens it
  # in a native modal overlay instead of navigating the main window.
  def new
    @task = Task.new
  end

  # GET /tasks/:id/edit — also opens in a modal window
  def edit
  end

  def create
    @task = Task.new(task_params)

    if @task.save
      # After creating, redirect to the task list.
      # The modal will close automatically when navigation happens.
      redirect_to tasks_path, notice: "Task created successfully!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @task.update(task_params)
      redirect_to tasks_path, notice: "Task updated successfully!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @task.destroy
    redirect_to tasks_path, notice: "Task deleted."
  end

  private

  def set_task
    @task = Task.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:title, :description, :priority, :completed)
  end
end
