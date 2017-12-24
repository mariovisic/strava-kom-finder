require 'spec_helper'

require 'strava_cacher'

RSpec.describe StravaAPICacheWrapper do
  describe '#fetch_activity' do
    context 'when the activity is already cached' do
      it 'returns the cached activity' do

        StravaAPICacheWrapper.load!("#{File.open(File.dirname(__FILE__))}support/cached_activity_test.json")

      end
    end
  end
end
