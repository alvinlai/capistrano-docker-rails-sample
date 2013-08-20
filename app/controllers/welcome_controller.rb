class WelcomeController < ApplicationController
  def index
    render text: "It worked - #{Time.now} - #{hostname}"
  end

  private

  def hostname
    %x(hostname)
  end
end
