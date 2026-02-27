class RoomsController < ApplicationController
  def index
    rooms = Room.all
    render json: { rooms: rooms.map { |r| room_json(r) } }, status: :ok
  end

  def show
    room = Room.find(params[:id])
    render json: { room: room_json(room) }, status: :ok
  end

  def create
    use_case = CreateRoomUseCase.new(room_params, current_user)
    result = use_case.call

    if result[:success]
      render json: { room: room_json(result[:room]) }, status: :created
    else
      render json: { errors: result[:errors] }, status: :unprocessable_entity
    end
  end

  def availability
    room = Room.find(params[:id])
    date = Date.parse(params[:date])
    use_case = GetRoomAvailabilityUseCase.new(room, date)
    result = use_case.call

    render json: { availability: result[:availability] }, status: :ok
  end

  private

  def room_params
    params.require(:room).permit(:name, :capacity, :has_projector, :has_video_conference, :floor)
  end

  def current_user
    @current_user ||= User.find(params[:user_id]) if params[:user_id]
  end

  def room_json(room)
    {
      id: room.id,
      name: room.name,
      capacity: room.capacity,
      has_projector: room.has_projector,
      has_video_conference: room.has_video_conference,
      floor: room.floor
    }
  end
end
