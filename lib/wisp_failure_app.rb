# Warden bounces a correct-password login when the account isn't confirmed, but
# Devise only sets a flash -- it never sends a token. Accounts created before
# confirmable was added (migration 20240321164518) have no confirmation_token at
# all, so there is nothing for them to act on. Resend one so they can self-serve.
#
# This only fires on :unconfirmed, which Devise's activatable hook throws *after*
# the password has already validated, so it can't be used to spray email at
# arbitrary addresses.
class WispFailureApp < Devise::FailureApp
  def respond
    @confirmation_resent = resend_confirmation_instructions if warden_message == :unconfirmed
    super
  end

  private

  def resend_confirmation_instructions
    email = attempted_email
    return false if email.blank?
    # Devise normalizes the email (case/whitespace) and no-ops if already confirmed.
    scope_class.send_confirmation_instructions(email: email)
    true
  rescue => e
    Rails.logger.error "WispFailureApp :: Failed to resend confirmation instructions: #{e.message}"
    false
  end

  def attempted_email
    credentials = request.params[scope.to_s]
    credentials.is_a?(Hash) ? credentials["email"] : nil
  end

  def i18n_message(default = nil)
    return super unless @confirmation_resent
    I18n.t(:unconfirmed_instructions_sent, scope: [:devise, :failure])
  end
end
