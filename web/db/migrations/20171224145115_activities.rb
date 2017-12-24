Sequel.migration do
  change do
    create_table(:activities) do
      primary_key :id

      Integer :strava_segment_id, null: false
      Integer :user_id, null: false
      Integer :segment_count, default: 0, null: false
      Integer :downloaded_segments, default: 0, null: false
      String :api_data, null: false
    end

    add_index(:activities, :user_id)
  end
end

