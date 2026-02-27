class CreateRoomUseCase
  def initialize(params, current_user)
    @params = params
    @current_user = current_user
  end

  def call
    unless @current_user&.is_admin?
      return { success: false, errors: ["Only admins can create rooms"] }
    end

    room = Room.new(@params)
    
    if room.save
      { success: true, room: room }
    else
      { success: false, errors: room.errors.full_messages }
    end
  end
end
