require 'rails_helper'

RSpec.describe Reservation, type: :model do
  describe 'validations' do
    describe '#recurring_until_not_present_without_recurring' do
      it 'is valid with recurring nil and recurring_until nil' do
        reservation = build(:reservation, recurring: nil, recurring_until: nil)
        expect(reservation).to be_valid
      end

      it 'is valid with recurring daily and recurring_until set' do
        reservation = build(:reservation, recurring: "daily", recurring_until: Date.today + 1.week)
        expect(reservation).to be_valid
      end

      it 'is valid with recurring weekly and recurring_until set' do
        reservation = build(:reservation, recurring: "weekly", recurring_until: Date.today + 1.month)
        expect(reservation).to be_valid
      end

      it 'is invalid with recurring monthly' do
        reservation = build(:reservation, recurring: "monthly", recurring_until: Date.today + 1.month)
        expect(reservation).not_to be_valid
        expect(reservation.errors[:recurring]).to include("is not included in the list")
      end

      it 'is invalid with recurring daily and recurring_until nil' do
        reservation = build(:reservation, recurring: "daily", recurring_until: nil)
        expect(reservation).not_to be_valid
        expect(reservation.errors[:recurring_until]).to include("can't be blank")
      end

      it 'is invalid with recurring nil and recurring_until set' do
        reservation = build(:reservation, recurring: nil, recurring_until: Date.today + 1.week)
        expect(reservation).not_to be_valid
        expect(reservation.errors[:recurring_until]).to include("can't be set without a recurring frequency")
      end
    end

    describe '#starts_before_ends' do
      let(:base_time) { Time.zone.now.next_week(:monday).change(hour: 12) }

      it 'is valid when starts_at is before ends_at' do
        reservation = build(:reservation, starts_at: base_time, ends_at: base_time + 1.hour)
        expect(reservation).to be_valid
      end

      it 'is invalid when starts_at is after ends_at' do
        reservation = build(:reservation, starts_at: base_time, ends_at: base_time - 1.hour)
        expect(reservation).not_to be_valid
        expect(reservation.errors[:ends_at]).to include("must be after start time")
      end

      it 'is invalid when starts_at equals ends_at' do
        reservation = build(:reservation, starts_at: base_time, ends_at: base_time)
        expect(reservation).not_to be_valid
        expect(reservation.errors[:ends_at]).to include("must be after start time")
      end
    end

    describe '#max_duration' do
      let(:base_time) { Time.zone.now.next_week(:monday).change(hour: 12) }

      it 'is valid with 3 hour duration' do
        reservation = build(:reservation, starts_at: base_time, ends_at: base_time + 3.hours)
        expect(reservation).to be_valid
      end

      it 'is valid with 4 hour duration' do
        reservation = build(:reservation, starts_at: base_time, ends_at: base_time + 4.hours)
        expect(reservation).to be_valid
      end

      it 'is invalid with 5 hour duration' do
        reservation = build(:reservation, starts_at: base_time, ends_at: base_time + 5.hours)
        expect(reservation).not_to be_valid
        expect(reservation.errors[:ends_at]).to include("reservation cannot exceed 4 hours")
      end
    end

    describe '#business_hours' do
      let(:valid_monday_start) { Time.zone.now.next_week(:monday).change(hour: 9) }
      let(:valid_monday_end) { Time.zone.now.next_week(:monday).change(hour: 18) }
      let(:valid_friday_start) { Time.zone.now.next_week(:friday).change(hour: 9) }
      let(:valid_friday_end) { Time.zone.now.next_week(:friday).change(hour: 18) }
      let(:invalid_day_start) { Time.zone.now.next_week(:sunday).change(hour: 9) }
      let(:invalid_day_end) { Time.zone.now.next_week(:sunday).change(hour: 18) }

      it 'is valid when starts_at is at 9 AM on Monday' do
        reservation = build(:reservation, starts_at: valid_monday_start, ends_at: valid_monday_start + 1.hour)
        expect(reservation).to be_valid
      end

      it 'is invalid when starts_at is before 9 AM on Monday' do
        reservation = build(:reservation, starts_at: valid_monday_start - 1.hour, ends_at: valid_monday_start + 2.hours)
        expect(reservation).not_to be_valid
        expect(reservation.errors[:starts_at]).to include("must be at or after 9:00 AM")
      end

      it 'is invalid when ends_at is after 6 PM on Monday' do
        reservation = build(:reservation, starts_at: valid_monday_end, ends_at: valid_monday_end + 1.hour)
        expect(reservation).not_to be_valid
        expect(reservation.errors[:ends_at]).to include("must be at or before 6:00 PM")
      end

      it 'is valid when starts_at is at 9 AM on Friday' do
        reservation = build(:reservation, starts_at: valid_friday_start, ends_at: valid_friday_start + 1.hour)
        expect(reservation).to be_valid
      end

      it 'is invalid when starts_at is before 9 AM on Friday' do
        reservation = build(:reservation, starts_at: valid_friday_start - 1.hour, ends_at: valid_friday_start + 2.hours)
        expect(reservation).not_to be_valid
        expect(reservation.errors[:starts_at]).to include("must be at or after 9:00 AM")
      end

      it 'is invalid when ends_at is after 6 PM on Friday' do
        reservation = build(:reservation, starts_at: valid_friday_end, ends_at: valid_friday_end + 1.hour)
        expect(reservation).not_to be_valid
        expect(reservation.errors[:ends_at]).to include("must be at or before 6:00 PM")
      end

      it 'is invalid when starts_at is on Sunday' do
        reservation = build(:reservation, starts_at: invalid_day_start, ends_at: invalid_day_start + 1.hour)
        expect(reservation).not_to be_valid
        expect(reservation.errors[:base]).to include("reservations must be on weekdays")
      end

      it 'is invalid when ends_at is on Sunday' do
        reservation = build(:reservation, starts_at: invalid_day_end - 1.hour, ends_at: invalid_day_end)
        expect(reservation).not_to be_valid
        expect(reservation.errors[:base]).to include("reservations must be on weekdays")
      end
    end

    describe '#capacity_restriction' do
      let(:user) { create(:user, max_capacity_allowed: 10) }
      let(:valid_room) { create(:room, capacity: 5) }
      let(:invalid_room) { create(:room, capacity: 20) }

      it 'is valid when room capacity is within user limit' do
        reservation = build(:reservation, room: valid_room, user: user)
        expect(reservation).to be_valid
      end

      it 'is invalid when room capacity exceeds user limit' do
        reservation = build(:reservation, room: invalid_room, user: user)
        expect(reservation).not_to be_valid
        expect(reservation.errors[:room]).to include("capacity exceeds user's maximum allowed capacity")
      end
    end

    describe '#reservation_limit' do
      let(:user) { create(:user, is_admin: false) }
      let(:admin) { create(:user, is_admin: true) }
      let(:base_time) { Time.zone.now.next_week(:monday).change(hour: 9) }
      let!(:reservation_1_user) { create(:reservation, starts_at: base_time, ends_at: base_time + 1.hour, user: user) }
      let!(:reservation_2_user) { create(:reservation, starts_at: base_time + 1.hour, ends_at: base_time + 2.hours, user: user) }
      let!(:reservation_cancelled_user) { create(:reservation, starts_at: base_time + 3.hours, ends_at: base_time + 4.hours, cancelled_at: Time.current, user: user) }
      let!(:reservation_1_admin) { create(:reservation, starts_at: base_time, ends_at: base_time + 1.hour, user: admin) }
      let!(:reservation_2_admin) { create(:reservation, starts_at: base_time + 1.hour, ends_at: base_time + 2.hours, user: admin) }
      let!(:reservation_cancelled_admin) { create(:reservation, starts_at: base_time + 3.hours, ends_at: base_time + 4.hours, cancelled_at: Time.current, user: admin) }

      it 'is valid when user has less than 3 future reservations' do
        reservation = build(:reservation, starts_at: base_time + 3.hours, ends_at: base_time + 4.hours, user: user)
        expect(reservation).to be_valid
      end

      it 'is invalid when user has 3 future reservations' do
        create(:reservation, starts_at: base_time + 3.hours, ends_at: base_time + 4.hours, user: user)
        reservation = build(:reservation, starts_at: base_time + 4.hours, ends_at: base_time + 5.hours, user: user)
        expect(reservation).not_to be_valid
        expect(reservation.errors[:base]).to include("cannot have more than 3 future reservations")
      end

      it 'is valid when admin has 3 or more future reservations' do
        create(:reservation, starts_at: base_time + 3.hours, ends_at: base_time + 4.hours, user: admin)
        reservation = build(:reservation, starts_at: base_time + 4.hours, ends_at: base_time + 5.hours, user: admin)
        expect(reservation).to be_valid
      end
    end

    describe '#no_overlapping_reservations' do
      let(:base_time) { Time.zone.now.next_week(:monday).change(hour: 9) }
      let(:room_2) { create(:room) }
      let!(:reservation_1) { create(:reservation, starts_at: base_time, ends_at: base_time + 1.hour) }
      let!(:cancelled_reservation) { create(:reservation, starts_at: base_time + 3.hours, ends_at: base_time + 4.hours, cancelled_at: Time.current) }

      it 'is valid when reservation does not overlap' do
        reservation = build(:reservation, room: reservation_1.room, starts_at: base_time + 1.hour, ends_at: base_time + 2.hours)
        expect(reservation).to be_valid
      end

      it 'is invalid when reservation has exact same time' do
        reservation = build(:reservation, room: reservation_1.room, starts_at: base_time, ends_at: base_time + 1.hour)
        expect(reservation).not_to be_valid
        expect(reservation.errors[:base]).to include("Room is already booked during this time")
      end

      it 'is invalid when reservation overlaps in the middle' do
        reservation = build(:reservation, room: reservation_1.room, starts_at: base_time + 30.minutes, ends_at: base_time + 90.minutes)
        expect(reservation).not_to be_valid
        expect(reservation.errors[:base]).to include("Room is already booked during this time")
      end

      it 'is invalid when reservation starts before and ends during existing reservation' do
        reservation = build(:reservation, room: reservation_1.room, starts_at: base_time - 30.minutes, ends_at: base_time + 30.minutes)
        expect(reservation).not_to be_valid
        expect(reservation.errors[:base]).to include("Room is already booked during this time")
      end

      it 'is valid when reservation is in different room' do
        reservation = build(:reservation, room: room_2, starts_at: base_time, ends_at: base_time + 1.hour)
        expect(reservation).to be_valid
      end

      it 'is valid when overlapping with cancelled reservation' do
        reservation = build(:reservation, room: cancelled_reservation.room, starts_at: base_time + 3.hours, ends_at: base_time + 4.hours)
        expect(reservation).to be_valid
      end
    end
  end
end
