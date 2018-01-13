class SegmentLeaderboardRepository
  # TODO: If leaderboards are stale, then will want to update them here!
  def self.fetch_or_create(strava_client, segment_id)
    existing_segment_leaderboards = DB[:segment_leaderboards].where(strava_segment_id: segment_id)
    if existing_segment_leaderboards.count > 0
      JSON.parse(existing_segment_leaderboards.first[:api_data])
    else
      strava_client.segment_leaderboards(segment_id).tap do |api_data|
        DB[:segment_leaderboards].insert(
          strava_segment_id: segment_id,
          api_data: JSON.dump(api_data),
          fetched_at: Time.now)
      end
    end
  end
end
