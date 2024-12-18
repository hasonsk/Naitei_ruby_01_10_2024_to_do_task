class TasksController < ApplicationController
  before_action :set_task, only: %i[destroy]
  before_action :logged_in_user, only: %i[create destroy]

  def new
    @task = Task.new
    @users = User.all
    @categories = current_user.categories
  end

  def index
    @tasks = Task.by_user current_user
    @categories = Category.all
    @tasks = @tasks.filter_by_category(params[:category])
                  .filter_by_status(params[:status])
                  .filter_by_deadline(params[:deadline])

    @pagy, @tasks = pagy @tasks, items: 5
  end

  def create
    @task = current_user.tasks.build(task_params)
    if @task.save
      @task.task_participants.create(user: current_user, role: :creator)
      assign_assignee if params[:task][:assignee_id].present?
      flash[:success] = t "tasks.task_create_successfully"
      redirect_to tasks_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

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

  def assign_assignee
    @task.task_participants.create(user_id: params[:task][:assignee_id], role: :assignee)
  end
end
