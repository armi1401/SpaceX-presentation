require 'rubygems'
require 'pry'
require 'bundler/setup'
require 'ostruct'
require 'json'
require 'httparty'
class LaunchesStatistic
  LAUNCHES_URL = 'https://api.spacexdata.com/v2/launches'
  ROCKETS_URL = 'https://api.spacexdata.com/v2/rockets'

  ROCKET_COSTS = ["falcon1", "falcon9", "falconheavy"].map do |rocket_id|
    rocket = HTTParty.get("#{ROCKETS_URL}/#{rocket_id}")
    cost = rocket['cost_per_launch']
    [rocket_id, cost]
  end.to_h

  def print
    launches_response = HTTParty.get(LAUNCHES_URL)

    launches = launches_response.map do |rocket_hash|
      JSON.parse(rocket_hash.to_json, object_class: OpenStruct)
    end

    puts number_of_launches_by_month(launches)

    puts mass_for_all_launches(launches)

    puts launches_cost_per_rocket(launches)

    puts launches_cost_per_year(launches)
  end

  private

  def number_of_launches_by_month(launches)
    launches_grouped_by_month = launches.group_by{ |launch| Date.parse(launch.launch_date_utc).month }.sort

    launches_grouped_by_month.map do |month, launches|
      number_of_flights = Array(launches).count
      "#{month} #{number_of_flights}"
    end
  end

  def mass_for_all_launches(launches)
    succesed_launches = launches.keep_if(&:launch_success)

    mass_for_all_launches = succesed_launches.map { |launch|   mass_for_single_launch(launch) }.sum
  end

  def launches_cost_per_rocket(launches)
    launches_grouped_by_rocket = launches.group_by { |launch| launch.rocket.rocket_name }

    launches_cost_per_rocket = launches_grouped_by_rocket.map do |rocket_name, launches|
      launches_count = Array(launches).count
      launches_cost = launches.map { |launch| cost_for_single_launch(launch) }.sum
      "#{rocket_name} #{launches_cost}"
    end
  end

  def launches_cost_per_year(launches)
    launches_grouped_by_year = launches.group_by{ |launch| launch.launch_year }

    launches_cost_per_year = launches_grouped_by_year.map do |year, launches|
      launches_cost = launches.map { |launch|  cost_for_single_launch(launch) }.sum
      "#{year} #{launches_cost}"
    end
  end

  def mass_for_single_launch(launch)
    payloads = launch.rocket.second_stage.payloads
    payloads.map { |payload| payload.payload_mass_kg.to_i }.sum
  end

  def cost_for_single_launch(launch)
    rocket_id = launch.rocket.rocket_id
    ROCKET_COSTS[rocket_id]
  end
end

LaunchesStatistic.new.print