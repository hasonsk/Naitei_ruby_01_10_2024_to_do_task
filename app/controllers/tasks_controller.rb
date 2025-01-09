class TasksController < ApplicationController
  before_action :set_task, only: %i[edit update destroy]
  before_action :logged_in_user, only: %i[create edit destroy]
  before_action :set_categories, :set_user, :available_users, only: %i[new index create edit update]
  before_action :set_comment, only: %i[edit]

  def new
    @task = Task.new
  end

  def index
    @tasks = current_user.mentor_role? ? Task.by_mentor_and_mentees(current_user.id) : current_user.tasks
    @tasks = @tasks.search(params[:search])
                   .filter_by_category(params[:category])
                   .filter_by_status(params[:status])

    if current_user.mentor_role? && params[:naitei].present?
      @tasks = @tasks.where(assignee_id: params[:naitei])
    end

    if current_user.naitei_role?
      if params[:role] == :creator
        @tasks = @tasks.where(user_id: current_user.id)
      elsif params[:role] == :assignee
        @tasks = @tasks.where(assignee_id: current_user.id)
      end
    end

    @pagy, @tasks = pagy @tasks, limit: Settings.default.max_tasks_per_page_5
  end

  def create
    @task = current_user.tasks.build(task_params)
    if @task.save
      flash[:success] = t "tasks.task_create_successfully"
      ActivityLogger.log(
        user: current_user,
        task: @task,
        action: "created",
        description: t("tasks.create.created_task", title: @task.title, id: @task.id)
      )
      redirect_to edit_task_path @task
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @subtasks = @task.subtasks
    @activities = @task.activities.includes(:user)
    @pagy, @subtasks = pagy @subtasks, limit: Settings.default.max_tasks_per_page_5
  end

  def update
    @task.assign_attributes(task_params)
    changes = @task.changes.transform_values { |change| { old: change[0], new: change[1] } }

    if @task.update(task_params)
      flash[:success] = t("tasks.update.successfully_updated")
      log_task_update(@task, changes)
      redirect_to edit_task_path(@task.parent_task || @task)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    task_deleted = @task.dup

    if @task.destroy
      if task_deleted.parent_task_id
        ActivityLogger.log(user: current_user, task: Task.find_by(id: (task_deleted.parent_task_id)), action: "deleted", description: t("tasks.delete.deleted_subtask", title: task_deleted.title, id: task_deleted.id))
      end
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

  def set_user
    @user = current_user
  end

  def set_task
    @task = Task.find_by(id: params[:id])
    return if @task

    flash[:error] = t "tasks.not_found"
    redirect_to tasks_url, status: :see_other
  end

  def available_users
    @users = current_user.mentor_role? ? current_user.mentees : [ current_user ]
  end

  def set_categories
    @categories = current_user.categories
  end

  def set_comment
    @comments = @task.comments
  end

  def log_task_update(task, changes)
    if task.parent_task_id.present?
      ActivityLogger.log(
        user: current_user,
        task: task.parent_task,
        action: "updated",
        description: t("tasks.update.updated_subtask", title: task.title, id: task.id)
      )
    else
      ActivityLogger.log(
        user: current_user,
        task: task,
        action: "updated",
        changes: changes
      )
    end
  end
end
