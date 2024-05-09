shared_examples 'A valid query condition' do
  before :all do
    raise '+@comp+ should be defined in before block' unless instance_variable_get(:@comp)
  end

  it 'is valid' do
    expect(@comp).to be_valid
  end
end
