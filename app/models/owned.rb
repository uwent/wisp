module Owned
  def owner
    raise NotImplementedError.new "Subclasses of Owned must override the owner method"
  end
  
  def auth(actor,action,opts={})
    logger.info "attempt by #{actor.inspect} to '#{action.to_s}' #{self.inspect}"
    actor == owner
  end
end