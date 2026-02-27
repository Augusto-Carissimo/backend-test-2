class CreateReservationUseCase
  def initialize(params, current_user)
    @params = params
    @current_user = current_user
  end

  def call
    if @params[:recurring].present?
      create_recurring_reservations
    else
      create_single_reservation
    end
  end

  private

  def create_single_reservation
    reservation = Reservation.new(@params.to_h.merge(user: @current_user))
    
    if reservation.save
      { success: true, reservations: [reservation] }
    else
      { success: false, errors: reservation.errors }
    end
  end

  def create_recurring_reservations
    result = Reservation.create_with_recurrences(@params.to_h.symbolize_keys, @current_user)
    
    if result.is_a?(Array)
      { success: true, reservations: result }
    else
      { success: false, errors: result.errors }
    end
  end
end
