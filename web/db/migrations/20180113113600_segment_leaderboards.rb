Sequel.migration do
  change do
    create_table(:segment_leaderboards) do
      primary_key :id

      Integer :strava_segment_id, null: false
      String :api_data, null: false
      DateTime :fetched_at, null: false
    end

    add_index(:segment_leaderboards, :strava_segment_id)
  end
end
