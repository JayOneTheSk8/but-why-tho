require "rails_helper"

RSpec.describe Post do
  it_behaves_like "text must be question(s)", :post
end
