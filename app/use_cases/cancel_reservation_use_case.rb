class CancelReservationUseCase
  def initialize(reservation)
    @reservation = reservation
  end

  def call
    if can_cancel?
      @reservation.update!(cancelled_at: Time.current)
      { success: true, reservation: @reservation }
    else
      { success: false, error: "A reservation can only be cancelled if there are more than 60 minutes until its start time." }
    end
  end

  private

  def can_cancel?
    Time.current < @reservation.starts_at - 1.hour
  end
end
