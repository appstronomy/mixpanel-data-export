require 'rspec'

describe 'The Mixpanel Service' do

  before :each do
    @service = Mixpanel::Service.new
  end

  it 'should should be an instance of Mixpanel::Service' do
    expect(@service).to be_an_instance_of Mixpanel::Service
  end

end