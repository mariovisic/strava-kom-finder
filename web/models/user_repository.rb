class UserRepository
  def self.create_or_update(access_token, data)
    existing_users = DB[:users].where(username: data['username'])

    if existing_users.count > 0
      existing_users.update(
        full_name: [data['firstname'], data['lastname']].join(' '),
        access_token: access_token,
        api_data: JSON.dump(data)
      )
    else
      DB[:users].insert(
        username: data['username'],
        full_name: [data['firstname'], data['lastname']].join(' '),
        access_token: access_token,
        api_data: JSON.dump(data)
      )
    end
  end
end
