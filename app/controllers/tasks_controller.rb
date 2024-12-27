class TasksController < ApplicationController
  before_action :set_task, only: %i[destroy update edit]
  before_action :logged_in_user, only: %i[create edit destroy]
  before_action :set_categories, :available_users, only: %i[new create edit update]

  def new
    @task = Task.new
  end

  def index
    @tasks = current_user.mentor? ? Task.all : Task.by_naitei(current_user.id)

    @pagy, @tasks = pagy @tasks, limit: 5
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

  def create_subtask
    @task = Task.find_by(id: params[:id])
    Rails.logger.debug "Creating subtask with params: #{subtask_params[:task][:subtasks_attributes].values.inspect}"
    if @task.nil?
      flash[:error] = t("tasks.parent_task_not_found")
      redirect_to tasks_path and return
    end
    @subtask = @task.subtasks.build(subtask_params[:subtasks_attributes].values.first)

    if @subtask.save
      flash[:success] = t("tasks.subtask_create_successfully")
      redirect_to edit_task_path(@task)
    else
      @subtasks = @task.subtasks
      flash.now[:error] = t("tasks.failed_to_create_subtask")
      render :edit, status: :unprocessable_entity
    end
  end

  def edit
    @task.subtasks.build if @task.subtasks.empty?
    @subtasks = @task.subtasks
    @pagy, @subtasks = pagy @subtasks, limit: 5
  end

  def update
    if @task.update(task_params)
      flash[:success] = t("tasks.successfully_updated")
      redirect_to tasks_path
    else
      render :edit
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

  def subtask_params
    params.require(:task).permit(Task::TASK_PERMITTED_ATTRIBUTES, subtasks_attributes: %i[title description priority status start_date deadline category_id assignee_id])
  end

  def set_task
    # flash[:error] = "#{params[:task_id]}"
    @task = Task.find_by(id: params[:parent_task_id])
    return if @task

    # flash[:error] = t "tasks.not_found"
    redirect_to tasks_url, status: :see_other
  end

  def available_users
    @users = current_user.mentor? ? User.all : [ current_user ]
  end

  def set_categories
    @categories = current_user.categories
  end
end
