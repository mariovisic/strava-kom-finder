class SegmentEffortRepository
  def self.create(activity_id, data)
    DB[:segment_efforts].insert(
      strava_segment_id: data['segment']['id'],
      activity_id: activity_id,
      api_data: JSON.dump(data)
    )

    DB[:activities].where(id: activity_id).update(Sequel.lit('downloaded_segment_efforts = downloaded_segment_efforts + 1'))
  end

  def self.find_all_for_user_id(user_id)
    DB[:segment_efforts].join(:activities, id: :activity_id).join(:users, id: :user_id).where(Sequel.lit('users.id = ?', user_id)).select(Sequel.lit('segment_efforts.*'))
  end
end
