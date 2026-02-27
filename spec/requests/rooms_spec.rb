require 'rails_helper'

RSpec.describe "Rooms API", type: :request do
  let(:admin_user) { create(:user, :admin) }
  let(:regular_user) { create(:user) }

  describe "GET /api/v1/rooms" do
    it "returns all rooms" do
      room1 = create(:room, name: "Conference Room A")
      room2 = create(:room, name: "Conference Room B")

      get "/api/v1/rooms"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["rooms"]).to be_an(Array)
      expect(json["rooms"].length).to eq(2)
      expect(json["rooms"].map { |r| r["name"] }).to contain_exactly("Conference Room A", "Conference Room B")
    end

    it "returns empty array when no rooms exist" do
      get "/api/v1/rooms"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["rooms"]).to eq([])
    end
  end

  describe "GET /api/v1/rooms/:id" do
    it "returns a specific room" do
      room = create(:room, name: "Conference Room A", capacity: 10, has_projector: true)

      get "/api/v1/rooms/#{room.id}"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["room"]["id"]).to eq(room.id)
      expect(json["room"]["name"]).to eq("Conference Room A")
      expect(json["room"]["capacity"]).to eq(10)
      expect(json["room"]["has_projector"]).to eq(true)
    end
  end

  describe "POST /api/v1/rooms" do
    context "when user is admin" do
      it "creates a new room" do
        expect {
          post "/api/v1/rooms", params: {
            user_id: admin_user.id,
            room: {
              name: "New Conference Room",
              capacity: 15,
              has_projector: true,
              has_video_conference: false,
              floor: 2
            }
          }
        }.to change(Room, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["room"]["name"]).to eq("New Conference Room")
        expect(json["room"]["capacity"]).to eq(15)
        expect(json["room"]["has_projector"]).to eq(true)
      end
    end

    context "when user is not admin" do
      it "does not create a room and returns error" do
        expect {
          post "/api/v1/rooms", params: {
            user_id: regular_user.id,
            room: {
              name: "New Conference Room",
              capacity: 15,
              has_projector: true,
              has_video_conference: false,
              floor: 2
            }
          }
        }.not_to change(Room, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to include("Only admins can create rooms")
      end
    end
  end

  describe "GET /api/v1/rooms/:id/availability" do
    it "returns availability slots for a specific date" do
      room = create(:room)
      date = Date.tomorrow

      get "/api/v1/rooms/#{room.id}/availability", params: { date: date.to_s }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["availability"]).to be_an(Array)
      expect(json["availability"].length).to eq(9)
      expect(json["availability"].first).to have_key("start_time")
      expect(json["availability"].first).to have_key("end_time")
      expect(json["availability"].first).to have_key("available")
    end

    it "marks slots as unavailable when there are reservations" do
      room = create(:room)
      user = create(:user)
      date = Time.zone.now.next_occurring(:monday).to_date
      starts_at = date.to_time.in_time_zone.change(hour: 10, min: 0)
      ends_at = starts_at + 2.hours

      create(:reservation, room: room, user: user, starts_at: starts_at, ends_at: ends_at)

      get "/api/v1/rooms/#{room.id}/availability", params: { date: date.to_s }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      
      slot_10am = json["availability"].find { |s| s["start_time"] == "10:00" }
      slot_11am = json["availability"].find { |s| s["start_time"] == "11:00" }
      slot_12pm = json["availability"].find { |s| s["start_time"] == "12:00" }
      
      expect(slot_10am["available"]).to eq(false)
      expect(slot_11am["available"]).to eq(false)
      expect(slot_12pm["available"]).to eq(true)
    end
  end
end
