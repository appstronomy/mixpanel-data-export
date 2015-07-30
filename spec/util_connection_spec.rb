require_relative 'spec_helper'


describe 'Connection' do

  before :each do
    @connection = Util::Connection.new('http://mixpanel.com')
  end


  it 'should be an instance of Util::Connection' do
    expect(@connection).to be_an_instance_of Util::Connection
  end

end