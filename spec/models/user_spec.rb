require "rails_helper"

describe User do
  before do
    allow_any_instance_of(Field)
      .to receive(:date_endpoints)
      .and_return([Date.yesterday, Date.today])
  end

  let(:user) { build :user }

  describe "#name" do
    context "when the first name and last name are present" do
      let(:user) { build :user, first_name: "Mark", last_name: "McEahern" }

      it "is the first name and the last name" do
        expect(user.name).to eq "Mark McEahern"
      end
    end

    context "when the first name is not present" do
      let(:user) { build :user, first_name: nil, last_name: "McEahern" }

      it "is just the last name" do
        expect(user.name).to eq "McEahern"
      end
    end

    context "when the last name is not present" do
      let(:user) { build :user, first_name: "Mark", last_name: nil }

      it "is just the first name" do
        expect(user.name).to eq "Mark"
      end
    end

    context "when neither first nor last name is present" do
      let(:user) { build :user, first_name: nil, last_name: nil }

      it "is empty" do
        expect(user.name).to be_empty
      end
    end
  end

  describe "#group_description" do
    let(:user) { build :user, first_name: "Mark", last_name: "McEahern" }

    it "indicates the group owner" do
      expect(user.group_description).to eq("Mark McEahern's group")
    end
  end

  describe "creating a user" do
    let(:user) { build :user }

    it "creates a group" do
      expect { user.save }.to change { user.groups.count }.by(1)
    end

    it "creates an admin membership" do
      expect { user.save }.to change { user.memberships.admin.count }.by(1)
    end

    it "is not an admin" do
      expect(user.admin).to be_falsey
    end
  end

  describe "#destroy" do
    it "will remove group if user is admin of group" do
      user.save!
      user.reload
      expect { user.destroy }.to change { Group.count }
    end

    it "will remove memberships" do
      user = create :user
      expect { user.destroy }.to change { Membership.count }
    end
  end
end
