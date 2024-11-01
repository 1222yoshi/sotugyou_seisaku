class Album < ApplicationRecord
  has_many :user_albums, dependent: :destroy
  has_many :users, through: :user_albums

  require 'net/http'
  require 'uri'
  require 'json'

  def self.search_albums(term)
    encoded_term = URI::encode_www_form_component(term)
    url = URI.parse("https://itunes.apple.com/search?term=#{encoded_term}&media=music&entity=album&country=jp")
    response = Net::HTTP.get_response(url)

    if response.is_a?(Net::HTTPSuccess)
      album_data = JSON.parse(response.body)
      album_data['results']
    else
      nil
    end
  end

  def self.search_tracks(term)
    encoded_term = URI::encode_www_form_component(term)
    url = URI.parse("https://itunes.apple.com/search?term=#{encoded_term}&media=music&entity=musicTrack&country=jp")
    response = Net::HTTP.get_response(url)

    if response.is_a?(Net::HTTPSuccess)
      album_data = JSON.parse(response.body)
      album_data['results']
    else
      nil
    end
  end

  def self.lookup(id)
    url = URI.parse("https://itunes.apple.com/lookup?id=#{id}&media=music&entity=album&country=jp")
    response = Net::HTTP.get_response(url)

    if response.is_a?(Net::HTTPSuccess)
      album_data = JSON.parse(response.body)
      album_data['results'].first
    else
      nil
    end
  end
end
