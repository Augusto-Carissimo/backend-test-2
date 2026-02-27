class ReservationsController < ApplicationController
  def create
    use_case = CreateReservationUseCase.new(reservation_params, current_user)
    result = use_case.call

    if result[:success]
      render json: { 
        reservations: result[:reservations].map { |r| reservation_json(r) }
      }, status: :created
    else
      render json: { errors: result[:errors].full_messages }, status: :unprocessable_entity
    end
  end

  def cancel
    reservation = Reservation.find(params[:id])
    use_case = CancelReservationUseCase.new(reservation)
    result = use_case.call

    if result[:success]
      render json: { reservation: reservation_json(result[:reservation]) }, status: :ok
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  private

  def reservation_params
    params.require(:reservation).permit(
      :room_id,
      :starts_at,
      :ends_at,
      :recurring,
      :recurring_until,
      :title
    )
  end

  def current_user
    @current_user ||= User.find(params[:user_id])
  end

  def reservation_json(reservation)
    {
      id: reservation.id,
      room_id: reservation.room_id,
      user_id: reservation.user_id,
      title: reservation.title,
      starts_at: reservation.starts_at,
      ends_at: reservation.ends_at,
      recurring: reservation.recurring,
      recurring_until: reservation.recurring_until,
      cancelled_at: reservation.cancelled_at
    }
  end
end
