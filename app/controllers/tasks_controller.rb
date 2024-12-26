class TasksController < ApplicationController
  before_action :set_task, only: %i[edit update destroy]
  before_action :logged_in_user, only: %i[create edit destroy]
  before_action :authorize_user!, only: %i[update destroy]
  before_action :set_categories, :available_users, only: %i[new create index edit update create_subtask]

  def new
    @task = Task.new
  end

  def index
    @tasks = current_user.mentor? ? Task.all : Task.by_naitei(current_user.id)

    @tasks = @tasks.search(params[:search])
                   .filter_by_category(params[:category])
                   .filter_by_status(params[:status])

    if current_user.mentor? && params[:naitei].present?
      @tasks = @tasks.where(assignee_id: params[:naitei])
    end

    if current_user.naitei?
      if params[:role] == :creator
        @tasks = @tasks.where(user_id: current_user.id)
      elsif params[:role] == :assignee
        @tasks = @tasks.where(assignee_id: current_user.id)
      end
    end

    @pagy, @tasks = pagy(@tasks, limit: 5)
  end

  def create
    @task = current_user.tasks.build(task_params)
    @task.assignee_id ||= current_user.id

    if @task.save
      ActivityLogger.log(user: current_user, task: @task, action: "created", description: t("tasks.create.created_task", id: @task.id))
      flash[:success] = t("tasks.successfully_created")
      redirect_to tasks_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def create_subtask
    @task = Task.find_by id: params[:parent_task_id]
    unless @task
      flash[:error] = t("tasks.parent_task_not_found")
      redirect_to tasks_path and return
    end

    @subtask = @task.subtasks.build(subtask_params)

    if @subtask.save
      ActivityLogger.log(user: current_user, task: @task, action: "created", description: t("tasks.create.created_subtask", id: @subtask.id))
      flash[:success] = t("tasks.subtask_create_successfully")
      redirect_to edit_task_path(@task)
    else
      @subtasks = @task.subtasks
      flash.now[:error] = t("tasks.failed_to_create_subtask")
      render :edit, status: :unprocessable_entity
    end
  end

  def edit
    @comments = @task.comments
    @subtasks = @task.subtasks
    @activities = @task.activities.includes(:user)
    @pagy, @subtasks = pagy(@subtasks, items: 5)
  end

  def update
    @task.assign_attributes(task_params)
    changes = @task.changes.transform_values { |change| { old: change[0], new: change[1] } }

    if @task.save
      if @task.parent_task_id
        ActivityLogger.log(user: current_user, task: Task.find_by(id: (@task.parent_task_id)), action: "updated", description: t("tasks.update.updated_subtask", id: @task.id))
      end
      ActivityLogger.log(user: current_user, task: @task, action: "updated", changes: changes)
      flash[:success] = t("tasks.index.messages.successfully_updated")
      redirect_to tasks_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    task_deleted = @task.dup
    if @task.destroy
      if task_deleted.parent_task_id
        ActivityLogger.log(user: current_user, task: Task.find_by(id: (task_deleted.parent_task_id)), action: "deleted", description: t("tasks.delete.deleted_subtask", id: task_deleted.id))
      end
      flash[:success] = t("tasks.task_deleted")
    else
      flash[:error] = t("tasks.failed_to_delete_the_task")
    end
    redirect_to tasks_url, status: :see_other
  end

  private

  def task_params
    params.require(:task).permit(Task::TASK_PERMITTED_ATTRIBUTES, task_participants_attributes: %i[user_id])
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

    flash[:error] = t "tasks.not_found"
    redirect_to tasks_url, status: :see_other
  end

  def set_categories
    @categories = current_user.categories
  end

  def available_users
    @users = current_user.mentor? ? User.all : [ current_user ]
  end

  def authorize_user!
    if current_user.naitei? && @task.user_id != current_user.id && @task.assignee_id != current_user.id
      flash[:error] = t("tasks.errors.not_authorized")
      redirect_to tasks_path
    end
  end
end
