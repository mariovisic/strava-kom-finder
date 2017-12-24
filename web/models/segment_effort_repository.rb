class SegmentEffortRepository
  def self.create(activity_id, data)
    DB[:segment_efforts].insert(
      strava_segment_id: data['segment']['id'],
      activity_id: activity_id,
      api_data: JSON.dump(data)
    )

    DB[:activities].where(id: activity_id).update(Sequel.lit('downloaded_segment_efforts = downloaded_segment_efforts + 1'))
  end
end
