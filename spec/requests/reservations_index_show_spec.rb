require 'rails_helper'

RSpec.describe "Reservations API - Index and Show", type: :request do
  let(:user) { create(:user) }
  let(:room) { create(:room) }

  describe "GET /api/v1/reservations" do
    it "returns all reservations" do
      starts_at = Time.zone.now.next_occurring(:monday).change(hour: 10, min: 0)
      reservation1 = create(:reservation, user: user, room: room, starts_at: starts_at, ends_at: starts_at + 1.hour)
      reservation2 = create(:reservation, user: user, room: room, starts_at: starts_at + 2.hours, ends_at: starts_at + 3.hours)

      get "/api/v1/reservations"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["reservations"]).to be_an(Array)
      expect(json["reservations"].length).to eq(2)
    end

    it "returns empty array when no reservations exist" do
      get "/api/v1/reservations"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["reservations"]).to eq([])
    end
  end

  describe "GET /api/v1/reservations/:id" do
    it "returns a specific reservation" do
      starts_at = Time.zone.now.next_occurring(:monday).change(hour: 10, min: 0)
      reservation = create(:reservation, 
        user: user, 
        room: room, 
        starts_at: starts_at, 
        ends_at: starts_at + 1.hour,
        title: "Team Meeting"
      )

      get "/api/v1/reservations/#{reservation.id}"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["reservation"]["id"]).to eq(reservation.id)
      expect(json["reservation"]["room_id"]).to eq(room.id)
      expect(json["reservation"]["user_id"]).to eq(user.id)
      expect(json["reservation"]["title"]).to eq("Team Meeting")
    end
  end
end
