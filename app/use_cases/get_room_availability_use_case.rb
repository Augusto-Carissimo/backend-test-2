class GetRoomAvailabilityUseCase
  BUSINESS_START = 9
  BUSINESS_END = 18

  def initialize(room, date)
    @room = room
    @date = date
  end

  def call
    availability = generate_availability_slots

    { success: true, availability: availability }
  end

  private

  def generate_availability_slots
    slots = []
    current_time = @date.to_time.in_time_zone.change(hour: BUSINESS_START)
    end_time = @date.to_time.in_time_zone.change(hour: BUSINESS_END)

    while current_time < end_time
      slot_end = current_time + 1.hour
      
      slots << {
        start_time: current_time.strftime("%H:%M"),
        end_time: slot_end.strftime("%H:%M"),
        available: slot_available?(current_time, slot_end)
      }

      current_time = slot_end
    end

    slots
  end

  def slot_available?(start_time, end_time)
    !Reservation
      .where(room_id: @room.id)
      .where(cancelled_at: nil)
      .where("starts_at < ? AND ends_at > ?", end_time, start_time)
      .exists?
  end
end
