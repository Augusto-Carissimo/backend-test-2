class UsersController < ApplicationController
  def index
    users = User.all
    render json: { users: users.map { |u| user_json(u) } }, status: :ok
  end

  def show
    user = User.find(params[:id])
    render json: { user: user_json(user) }, status: :ok
  end

  def create
    use_case = CreateUserUseCase.new(user_params)
    result = use_case.call

    if result[:success]
      render json: { user: user_json(result[:user]) }, status: :created
    else
      render json: { errors: result[:errors].full_messages }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :department, :max_capacity_allowed, :is_admin)
  end

  def user_json(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      department: user.department,
      max_capacity_allowed: user.max_capacity_allowed,
      is_admin: user.is_admin
    }
  end
end
