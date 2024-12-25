class TasksController < ApplicationController
  before_action :set_task, only: %i[edit update destroy]
  before_action :logged_in_user, only: %i[create edit destroy]
  before_action :set_categories, only: %i[new create index edit update create_subtask]

  def new
    @task = Task.new
    @task.task_participants.build if @task.task_participants.empty?
    @users = User.all
  end

  def index
    @tasks = Task.by_user(current_user)
                 .filter_by_category(params[:category])
                 .filter_by_status(params[:status])
                 .filter_by_deadline(params[:deadline])
    @pagy, @tasks = pagy(@tasks, limit: 5)
  end

  def create
    @task = current_user.tasks.build(task_params)

    if @task.save
      @task.task_participants.create(user: current_user, role: :creator)
      assign_assignee if params[:task][:assignee_id].present?
      flash[:success] = t("tasks.successfully_created")
      redirect_to tasks_path
    else
      @users = User.all
      render :new, status: :unprocessable_entity
    end
  end

  def create_subtask
    @task = Task.find_by(id: params[:parent_task_id])
    unless @task
      flash[:error] = t("tasks.parent_task_not_found")
      redirect_to tasks_path and return
    end

    @subtask = @task.sub_tasks.build(subtask_params)

    if @subtask.save
      flash[:success] = t("tasks.subtask_create_successfully")
      redirect_to edit_task_path(@task)
    else
      @subtasks = @task.sub_tasks
      flash.now[:error] = t("tasks.failed_to_create_subtask")
      render :edit, status: :unprocessable_entity
    end
  end

  def edit
    @comments = @task.comments
    @subtasks = @task.sub_tasks
    @pagy, @subtasks = pagy(@subtasks, items: 5)
  end

  def update
    if @task.update(task_params)
      update_assignee if params[:task][:user_id].present?
      flash[:success] = t("tasks.index.messages.successfully_updated")
      redirect_to tasks_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @task.destroy
      flash[:success] = t("tasks.task_deleted")
    else
      flash[:error] = t("tasks.failed_to_delete_the_task")
    end
    redirect_to tasks_url, status: :see_other
  end

  private

  def task_params
    params.require(:task).permit(Task::TASK_PERMITTED_ATTRIBUTES, task_participants_attributes: [:user_id])
  end

  def subtask_params
    params.permit(Task::SUBTASK_PERMITTED_ATTRIBUTES)
  end

  def comment_params
    params.require(:comment).permit(Comment::COMMENT_PERMITTED_ATTRIBUTES)
  end

  def set_task
    @task = Task.find_by(id: params[:id])
    return if @task

    flash[:error] = t("tasks.not_found")
    redirect_to tasks_url, status: :see_other
  end

  def set_categories
    @categories = current_user.categories
  end

  def assign_assignee
    @task.task_participants.create(user_id: params[:task][:user_id], role: :assignee)
  end

  def update_assignee
    @task.task_participants.where(role: :assignee).destroy_all
    assign_assignee
  end
end
