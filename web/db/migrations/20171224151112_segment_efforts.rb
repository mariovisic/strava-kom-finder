Sequel.migration do
  change do
    create_table(:segment_efforts) do
      primary_key :id

      Integer :strava_segment_id, null: false
      Integer :activity_id, null: false
      String :api_data, null: false
    end

    add_index(:segment_efforts, :activity_id)
    add_index(:segment_efforts, :strava_segment_id)
  end
end

