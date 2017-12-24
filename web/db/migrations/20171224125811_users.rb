Sequel.migration do
  change do
    create_table(:users) do
      primary_key :id

      String :username, size: 255, null: false
      String :full_name, size: 255, null: false
      String :access_token, size: 100, null: false
      String :api_data, null: false

    end

    add_index(:users, :username)
  end
end

