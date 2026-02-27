require 'rails_helper'

RSpec.describe "Users API", type: :request do
  describe "GET /api/v1/users" do
    it "returns all users" do
      user1 = create(:user, name: "John Doe")
      user2 = create(:user, name: "Jane Smith")

      get "/api/v1/users"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["users"]).to be_an(Array)
      expect(json["users"].length).to eq(2)
      expect(json["users"].map { |u| u["name"] }).to contain_exactly("John Doe", "Jane Smith")
    end

    it "returns empty array when no users exist" do
      get "/api/v1/users"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["users"]).to eq([])
    end
  end

  describe "GET /api/v1/users/:id" do
    it "returns a specific user" do
      user = create(:user, name: "John Doe", email: "john@example.com", department: "Engineering")

      get "/api/v1/users/#{user.id}"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["user"]["id"]).to eq(user.id)
      expect(json["user"]["name"]).to eq("John Doe")
      expect(json["user"]["email"]).to eq("john@example.com")
      expect(json["user"]["department"]).to eq("Engineering")
    end
  end

  describe "POST /api/v1/users" do
    context "with valid parameters" do
      it "creates a new user" do
        expect {
          post "/api/v1/users", params: {
            user: {
              name: "New User",
              email: "newuser@example.com",
              department: "Marketing",
              max_capacity_allowed: 10,
              is_admin: false
            }
          }
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["user"]["name"]).to eq("New User")
        expect(json["user"]["email"]).to eq("newuser@example.com")
        expect(json["user"]["department"]).to eq("Marketing")
        expect(json["user"]["is_admin"]).to eq(false)
      end
    end

    context "with invalid parameters" do
      it "does not create a user and returns errors" do
        expect {
          post "/api/v1/users", params: {
            user: {
              name: "",
              email: "",
              department: "Marketing"
            }
          }
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["errors"]).to be_an(Array)
      end
    end
  end
end
