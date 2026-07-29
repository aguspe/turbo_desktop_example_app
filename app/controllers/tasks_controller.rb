class TasksController < ApplicationController
  before_action :set_task, only: %i[show edit update destroy]

  def index
    @tasks = Task.order(created_at: :desc)

    respond_to do |format|
      format.html
      # Plain CSV of every task. The desktop export button fetches this and
      # writes it wherever the user pointed the native save dialog.
      format.csv do
        csv = "title,description,priority,completed\n" + @tasks.map { |t|
          [ t.title, t.description, t.priority, t.completed ].map { |v| csv_field(v) }.join(",")
        }.join("\n")
        send_data csv, filename: "tasks.csv", type: "text/csv"
      end
    end
  end

  # POST /tasks/import — rows from a CSV the user dropped on the window or
  # opened with the app. The desktop shell hands the page real file paths;
  # the page reads them through the filesystem bridge and posts the text here.
  def import
    created = 0
    params.require(:csv).each_line.drop(1).each do |line|
      title, description, priority = line.strip.split(",", 3)
      next if title.blank?

      Task.create(title: title.delete('"'),
                  description: description.to_s.delete('"'),
                  priority: %w[low medium high].include?(priority.to_s.delete('"')) ? priority.delete('"') : "medium")
      created += 1
    end

    redirect_to tasks_path, notice: "Imported #{created} #{'task'.pluralize(created)}."
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

  def csv_field(value)
    text = value.to_s.gsub('"', '""')
    text.match?(/[",\n]/) ? "\"#{text}\"" : text
  end
end
