# This pulls in the config from spec/rails_helper.rb
# that's needed in order for the test to run.
require 'rails_helper'
# RSpec.describe, or just describe, is how all RSpec tests start.
# The 'Hello world' part is an arbitrary string and could have been anything.
# In this case we have something extra in our describe block, type: :feature.
# The type: :feature setting does have a functional purpose. It's what
# triggers RSpec to bring Capybara into the picture when we run the test.
RSpec.describe 'Hello world', type: :system do
# This "scenario" block is analogous to an RSpec "it" block. In fact, if
# we were to replace "scenario 'index page'" with "it 'index page'", this
# test would still function the exact same way, although it would arguably
# read much less naturally. "scenario" is just syntactic sugar for "it".
  scenario 'index page' do
  # This is where Capybara starts to come into the picture. "visit" is a
  # Capybara method. hello_world_index_path is just a Rails routing
  # helper method and has nothing to do with RSpec or Capybara.
    visit hello_world_index_path
    # The following is a mix of RSpec syntax and Capybara syntax. "expect"
    # and "to" are RSpec, "page" and "have_content" are Capybara. Newcomers
    # to RSpec and Capybara's English-sentence-like constructions often
    # have difficulty remembering when two words are separated by a dot or
    # an underscore or parenthesis, myself included. Don't worry, you'll
    # get familiar over time.
    expect(page).to have_content('Hello, world!')
  end
end
