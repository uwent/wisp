require "rails_helper"

describe "Logging in with an unconfirmed account", type: :request do
  # Mirrors accounts created before the confirmable migration: no confirmed_at,
  # and no confirmation token was ever generated for them.
  let!(:user) do
    create(:user, email: "old@example.com", password: "password", confirmed_at: nil).tap do |u|
      u.update_columns(confirmation_token: nil, confirmation_sent_at: nil)
    end
  end

  def log_in(email: "old@example.com", password: "password")
    post user_session_path, params: {user: {email: email, password: password}}
  end

  before { ActionMailer::Base.deliveries.clear }

  it "does not sign the user in" do
    log_in
    expect(response).to redirect_to(new_user_session_path)
  end

  it "tells the user their email needs confirming" do
    log_in
    expect(flash[:alert]).to match(/confirm your email address/i)
  end

  it "emails a fresh confirmation link" do
    expect { log_in }.to change { ActionMailer::Base.deliveries.size }.by(1)
    expect(ActionMailer::Base.deliveries.last.to).to eq(["old@example.com"])
    expect(user.reload.confirmation_token).to be_present
  end

  it "lets the user log in once they follow the link" do
    log_in
    get user_confirmation_path(confirmation_token: user.reload.confirmation_token)
    expect(user.reload.confirmed_at).to be_present

    log_in
    expect(response).to redirect_to(root_path)
  end

  it "ignores case and surrounding whitespace in the submitted email" do
    expect { log_in(email: " OLD@Example.com ") }
      .to change { ActionMailer::Base.deliveries.size }.by(1)
  end

  it "does not email anyone when the password is wrong" do
    expect { log_in(password: "wrong") }.not_to change { ActionMailer::Base.deliveries.size }
    expect(flash[:alert]).to match(/invalid/i)
  end

  it "does not email an already confirmed user" do
    user.update_columns(confirmed_at: Time.current)
    expect { log_in }.not_to change { ActionMailer::Base.deliveries.size }
    expect(response).to redirect_to(root_path)
  end
end
