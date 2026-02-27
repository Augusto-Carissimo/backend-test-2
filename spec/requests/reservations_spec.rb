require 'rails_helper'

RSpec.describe "Reservations API", type: :request do
  include ActiveSupport::Testing::TimeHelpers
  let(:user) { create(:user) }
  let(:room) { create(:room) }
  
  describe "POST /reservations" do
    context "single reservation (no recurring)" do
      context "with valid parameters" do
        it "creates a single reservation" do
          starts_at = Time.zone.now.next_occurring(:monday).change(hour: 10, min: 0)
          ends_at = starts_at + 1.hour

          expect {
            post "/reservations", params: {
              user_id: user.id,
              reservation: {
                room_id: room.id,
                starts_at: starts_at,
                ends_at: ends_at,
                title: "Team meeting"
              }
            }
          }.to change(Reservation, :count).by(1)

          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)
          expect(json["reservations"]).to be_an(Array)
          expect(json["reservations"].length).to eq(1)
          expect(json["reservations"][0]["room_id"]).to eq(room.id)
          expect(json["reservations"][0]["user_id"]).to eq(user.id)
        end
      end
    end

    context "recurring reservations" do
      context "when all occurrences are valid" do
        it "creates all recurring reservations" do
          starts_at = Time.zone.now.next_occurring(:monday).change(hour: 10, min: 0)
          ends_at = starts_at + 1.hour
          recurring_until = (starts_at + 2.weeks).to_date

          expect {
            post "/reservations", params: {
              user_id: user.id,
              reservation: {
                room_id: room.id,
                starts_at: starts_at,
                ends_at: ends_at,
                recurring: "weekly",
                recurring_until: recurring_until,
                title: "Weekly standup"
              }
            }
          }.to change(Reservation, :count).by(3)

          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)
          expect(json["reservations"]).to be_an(Array)
          expect(json["reservations"].length).to eq(3)
        end
      end

      context "when one occurrence falls on a weekend" do
        it "does not create any reservations" do
          starts_at = Time.zone.now.next_occurring(:saturday).change(hour: 10, min: 0)
          ends_at = starts_at + 1.hour
          recurring_until = starts_at.to_date

          expect {
            post "/reservations", params: {
              user_id: user.id,
              reservation: {
                room_id: room.id,
                starts_at: starts_at,
                ends_at: ends_at,
                recurring: "weekly",
                recurring_until: recurring_until,
                title: "Weekend meeting"
              }
            }
          }.to_not change(Reservation, :count)

          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json["errors"]).to include("reservations must be on weekdays")
        end
      end

      context "when one occurrence overlaps with existing reservation" do
        it "does not create any reservations" do
          starts_at = Time.zone.now.next_occurring(:monday).change(hour: 10, min: 0)
          ends_at = starts_at + 1.hour
          
          create(:reservation, 
            room: room,
            user: user,
            starts_at: starts_at + 1.week,
            ends_at: ends_at + 1.week
          )

          recurring_until = (starts_at + 2.weeks).to_date

          expect {
            post "/reservations", params: {
              user_id: user.id,
              reservation: {
                room_id: room.id,
                starts_at: starts_at,
                ends_at: ends_at,
                recurring: "weekly",
                recurring_until: recurring_until,
                title: "Conflicting meeting"
              }
            }
          }.to_not change(Reservation, :count)

          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json["errors"]).to include("Room is already booked during this time")
        end
      end

      context "when one occurrence exceeds business hours" do
        it "does not create any reservations" do
          starts_at = Time.zone.now.next_occurring(:monday).change(hour: 17, min: 0)
          ends_at = starts_at + 2.hours
          recurring_until = (starts_at + 2.weeks).to_date

          expect {
            post "/reservations", params: {
              user_id: user.id,
              reservation: {
                room_id: room.id,
                starts_at: starts_at,
                ends_at: ends_at,
                recurring: "weekly",
                recurring_until: recurring_until,
                title: "Late meeting"
              }
            }
          }.to_not change(Reservation, :count)

          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json["errors"]).to include("Ends at must be at or before 6:00 PM")
        end
      end

      context "daily recurrence" do
        it "creates correct number of occurrences until recurring_until" do
          admin_user = create(:user, :admin)
          starts_at = Time.zone.now.next_occurring(:monday).change(hour: 10, min: 0)
          ends_at = starts_at + 1.hour
          recurring_until = (starts_at + 4.days).to_date

          expect {
            post "/reservations", params: {
              user_id: admin_user.id,
              reservation: {
                room_id: room.id,
                starts_at: starts_at,
                ends_at: ends_at,
                recurring: "daily",
                recurring_until: recurring_until,
                title: "Daily standup"
              }
            }
          }.to change(Reservation, :count).by(5)

          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)
          expect(json["reservations"].length).to eq(5)

          reservations = Reservation.where(room: room, user: admin_user).order(:starts_at)
          expect(reservations[0].starts_at.to_date).to eq(starts_at.to_date)
          expect(reservations[1].starts_at.to_date).to eq((starts_at + 1.day).to_date)
          expect(reservations[2].starts_at.to_date).to eq((starts_at + 2.days).to_date)
          expect(reservations[3].starts_at.to_date).to eq((starts_at + 3.days).to_date)
          expect(reservations[4].starts_at.to_date).to eq((starts_at + 4.days).to_date)
        end

        it "skips weekend days in daily recurrence" do
          admin_user = create(:user, :admin)
          starts_at = Time.zone.now.next_occurring(:thursday).change(hour: 10, min: 0)
          ends_at = starts_at + 1.hour
          recurring_until = (starts_at + 4.days).to_date

          expect {
            post "/reservations", params: {
              user_id: admin_user.id,
              reservation: {
                room_id: room.id,
                starts_at: starts_at,
                ends_at: ends_at,
                recurring: "daily",
                recurring_until: recurring_until,
                title: "Daily standup"
              }
            }
          }.to change(Reservation, :count).by(3)

          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)
          expect(json["reservations"].length).to eq(3)

          reservations = Reservation.where(room: room, user: admin_user).order(:starts_at)
          expect(reservations[0].starts_at.to_date).to eq(starts_at.to_date)
          expect(reservations[1].starts_at.to_date).to eq((starts_at + 1.day).to_date)
          expect(reservations[2].starts_at.to_date).to eq((starts_at + 4.days).to_date)
        end
      end

      context "weekly recurrence" do
        it "creates correct number of occurrences until recurring_until" do
          admin_user = create(:user, :admin)
          starts_at = Time.zone.now.next_occurring(:monday).change(hour: 10, min: 0)
          ends_at = starts_at + 1.hour
          recurring_until = (starts_at + 4.weeks).to_date

          expect {
            post "/reservations", params: {
              user_id: admin_user.id,
              reservation: {
                room_id: room.id,
                starts_at: starts_at,
                ends_at: ends_at,
                recurring: "weekly",
                recurring_until: recurring_until,
                title: "Weekly review"
              }
            }
          }.to change(Reservation, :count).by(5)

          expect(response).to have_http_status(:created)
          json = JSON.parse(response.body)
          expect(json["reservations"].length).to eq(5)

          reservations = Reservation.where(room: room, user: admin_user).order(:starts_at)
          expect(reservations[0].starts_at.to_date).to eq(starts_at.to_date)
          expect(reservations[1].starts_at.to_date).to eq((starts_at + 1.week).to_date)
          expect(reservations[2].starts_at.to_date).to eq((starts_at + 2.weeks).to_date)
          expect(reservations[3].starts_at.to_date).to eq((starts_at + 3.weeks).to_date)
          expect(reservations[4].starts_at.to_date).to eq((starts_at + 4.weeks).to_date)
        end
      end
    end
  end

  describe "PATCH /reservations/:id/cancel" do
    context "when cancellation is valid (more than 60 minutes before start time)" do
      it "cancels the reservation" do
        starts_at = Time.zone.now.next_occurring(:monday).change(hour: 14, min: 0)
        ends_at = starts_at + 1.hour
        reservation = create(:reservation, user: user, room: room, starts_at: starts_at, ends_at: ends_at)

        patch "/reservations/#{reservation.id}/cancel"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["reservation"]["cancelled_at"]).not_to be_nil
        
        reservation.reload
        expect(reservation.cancelled_at).not_to be_nil
      end
    end

    context "when cancellation is invalid (less than 60 minutes before start time)" do
      it "does not cancel the reservation and returns an error" do
        base_time = Time.zone.now.next_occurring(:monday).change(hour: 14, min: 0)
        starts_at = base_time + 30.minutes
        ends_at = starts_at + 1.hour
        
        reservation = create(:reservation, user: user, room: room, starts_at: starts_at, ends_at: ends_at)

        travel_to(base_time) do
          patch "/reservations/#{reservation.id}/cancel"

          expect(response).to have_http_status(:unprocessable_entity)
          json = JSON.parse(response.body)
          expect(json["error"]).to eq("A reservation can only be cancelled if there are more than 60 minutes until its start time.")
          
          reservation.reload
          expect(reservation.cancelled_at).to be_nil
        end
      end
    end
  end
end
