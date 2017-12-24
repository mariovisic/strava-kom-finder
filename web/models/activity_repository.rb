class ActivityRepository
  def self.create(user_id, data)
    DB[:activities].insert(
      strava_activity_id: data['id'],
      user_id: user_id,
      segment_count: data['segment_efforts'].length,
      api_data: JSON.dump(data)
    )
  end
end
