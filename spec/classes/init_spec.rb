require 'spec_helper'
describe 'django' do

  context 'with defaults for all parameters' do
    it { should contain_class('django') }
  end
end
