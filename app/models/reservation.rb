class Reservation < ApplicationRecord
  belongs_to :room
  belongs_to :user

  validates :recurring, inclusion: { in: ["daily", "weekly", nil] }
  validates :recurring_until, presence: true, if: -> { recurring.present? }

  validate :recurring_until_not_present_without_recurring
  validate :starts_before_ends
  validate :max_duration
  validate :business_hours
  validate :capacity_restriction
  validate :reservation_limit
  validate :no_overlapping_reservations

  def self.create_with_recurrences(params, user)
    occurrences = generate_occurrences(params)

    if occurrences.empty?
      reservation = new(params.merge(user: user))
      reservation.valid?
      return reservation
    end

    reservations = occurrences.map do |occurrence_params|
      new(occurrence_params.merge(user: user))
    end

    all_valid = reservations.all?(&:valid?)

    unless all_valid
      return reservations.find { |r| r.errors.any? }
    end

    transaction do
      reservations.each(&:save!)
    end

    reservations
  end

  private

  def self.generate_occurrences(params)
    starts_at       = params[:starts_at].is_a?(String) ? Time.zone.parse(params[:starts_at]) : params[:starts_at]
    ends_at         = params[:ends_at].is_a?(String) ? Time.zone.parse(params[:ends_at]) : params[:ends_at]
    recurring_until = params[:recurring_until].is_a?(String) ? Date.parse(params[:recurring_until]) : params[:recurring_until]
    duration        = ends_at - starts_at
    current         = starts_at

    step = case params[:recurring]
           when "daily"  then 1.day
           when "weekly" then 1.week
           end

    [].tap do |occurrences|
      while current.to_date <= recurring_until
        if current.on_weekday?
          occurrences << params.merge(starts_at: current, ends_at: current + duration)
        end
        current += step
      end
    end
  end

  private

  def recurring_until_not_present_without_recurring
    if recurring_until.present? && recurring.blank?
      errors.add(:recurring_until, "can't be set without a recurring frequency")
    end
  end

  def starts_before_ends
    return if starts_at.blank? || ends_at.blank?

    if ends_at <= starts_at
      errors.add(:ends_at, "must be after start time")
    end
  end

  def max_duration
    return if starts_at.blank? || ends_at.blank?

    if ends_at > (starts_at + 4.hours)
      errors.add(:ends_at, "reservation cannot exceed 4 hours")
    end
  end

  def business_hours
    return if starts_at.blank? || ends_at.blank?

    unless starts_at.on_weekday? && ends_at.on_weekday?
      errors.add(:base, "reservations must be on weekdays")
      return
    end

    start_hour = starts_at.hour
    end_hour = ends_at.hour
    end_minutes = ends_at.min

    if start_hour < 9
      errors.add(:starts_at, "must be at or after 9:00 AM")
    end

    if end_hour > 18 || (end_hour == 18 && end_minutes > 0)
      errors.add(:ends_at, "must be at or before 6:00 PM")
    end
  end

  def capacity_restriction
    return if user.blank? || room.blank?
    return if user.is_admin?

    if room.capacity > user.max_capacity_allowed
      errors.add(:room, "capacity exceeds user's maximum allowed capacity")
    end
  end

  def reservation_limit
    return if user.blank?
    return if user.is_admin?

    future_reservations = Reservation
      .where.not(id: id)
      .where(user_id: user_id)
      .where("starts_at > ?", Time.current)
      .where(cancelled_at: nil)
      .count

    if future_reservations >= 3
      errors.add(:base, "cannot have more than 3 future reservations")
    end
  end

  def no_overlapping_reservations
    return if room_id.blank? || starts_at.blank? || ends_at.blank?

    Reservation.transaction do
      Room.lock.find(room_id) if persisted? || room_id

      overlaps = Reservation
        .where(room_id: room_id)
        .where.not(id: id)
        .where(cancelled_at: nil)
        .where("starts_at < ? AND ends_at > ?", ends_at, starts_at)

      errors.add(:base, "Room is already booked during this time") if overlaps.exists?
    end
  end
end
