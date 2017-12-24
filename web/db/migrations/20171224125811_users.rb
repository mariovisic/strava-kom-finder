Sequel.migration do
  change do
    create_table(:users) do
      primary_key :id

      String :username, null: false
      String :full_name, null: false
      String :access_token, null: false
    end
  end
end

