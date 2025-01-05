class TasksController < ApplicationController
  before_action :set_task, only: %i[destroy edit update]
  before_action :logged_in_user, only: %i[create destroy]
  before_action :set_categories, :set_user, :available_users, only: %i[new index create edit]
  before_action :set_comment, only: %i[edit]

  def new
    @task = Task.new
  end

  def index
    @tasks = current_user.mentor? ? Task.by_mentor_and_mentees(current_user.id) : current_user.tasks

    @pagy, @tasks = pagy @tasks, limit: Settings.default.max_tasks_per_page_5
  end

  def create
    @task = current_user.tasks.build(task_params)
    if @task.save
      flash[:success] = t "tasks.task_create_successfully"
      redirect_to tasks_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @subtask = @task.subtasks.build
    @subtasks = @task.subtasks.where.not(id: nil)
    @pagy, @subtasks = pagy @subtasks, limit: Settings.default.max_tasks_per_page_5
  end

  def update
    if @task.update(task_params)
      flash[:success] = t("tasks.index.messages.successfully_updated")
      redirect_to tasks_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @task.destroy
      flash[:success] = t "tasks.task_deleted"
      redirect_to request.referer || tasks_url, status: :see_other
    else
      flash[:error] = t "tasks.failed_to_delete_the_task"
      redirect_to tasks_url
    end
  end

  private
  def task_params
    params.require(:task).permit(Task::TASK_PERMITTED_ATTRIBUTES)
  end

  def set_task
    @task = Task.find_by(id: params[:id])
    return if @task

    flash[:error] = t "tasks.not_found"
    redirect_to tasks_url, status: :see_other
  end

  def set_comment
    @comments = @task.comments
  end

  def set_user
    @user = current_user
  end

  def set_categories
    @categories = current_user.categories
  end

  def available_users
    @users = current_user.mentor? ? current_user.mentees : [ current_user ]
  end
end
