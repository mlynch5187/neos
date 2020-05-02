require 'faraday'
require 'figaro'
require 'pry'
# Load ENV vars via Figaro
Figaro.application = Figaro::Application.new(environment: 'production', path: File.expand_path('../config/application.yml', __FILE__))
Figaro.load

class NearEarthObjects

  def initialize
    @date = gets.chomp
    @astroid_details = NearEarthObjects.find_neos_by_date(@date)
    @astroid_list = @astroid_details[:astroid_list]
    @total_number_of_astroids = @astroid_details[:total_number_of_astroids]
    @largest_astroid = @astroid_details[:biggest_astroid]

    @column_labels = { name: "Name", diameter: "Diameter", miss_distance: "Missed The Earth By:" }
    @column_data = column_labels.each_with_object({}) do |(col, label), hash|
      hash[col] = {
        label: label,
        width: [astroid_list.map { |astroid| astroid[col].size }.max, label.size].max}
  end

  @header = "| #{ column_data.map { |_,col| col[:label].ljust(col[:width]) }.join(' | ') } |"
  @divider = "+-#{column_data.map { |_,col| "-"*col[:width] }.join('-+-') }-+"

  def format_row_data(row_data, column_info)
    row = row_data.keys.map { |key| row_data[key].ljust(column_info[key][:width]) }.join(' | ')
    puts "| #{row} |"
  end

  def create_rows(astroid_data, column_info)
    rows = astroid_data.each { |astroid| format_row_data(astroid, column_info) }
  end

  @formated_date = DateTime.parse(date).strftime("%A %b %d, %Y")

  def self.find_neos_by_date(date)
    conn = Faraday.new(
      url: 'https://api.nasa.gov',
      params: { start_date: @date, api_key: ENV['nasa_api_key']}
    )
    @asteroids_list_data = conn.get('/neo/rest/v1/feed')

    @parsed_asteroids_data = JSON.parse(@asteroids_list_data.body, symbolize_names: true)[:near_earth_objects][:"#{@date}"]

    @largest_astroid_diameter = @parsed_asteroids_data.map do |astroid|
      astroid[:estimated_diameter][:feet][:estimated_diameter_max].to_i
    end.max { |a,b| a<=> b}

    @total_number_of_astroids = @parsed_asteroids_data.count
    @formatted_asteroid_data = @parsed_asteroids_data.map do |astroid|
      {
        name: astroid[:name],
        diameter: "#{astroid[:estimated_diameter][:feet][:estimated_diameter_max].to_i} ft",
        miss_distance: "#{astroid[:close_approach_data][0][:miss_distance][:miles].to_i} miles"
      }
    end

    {
      astroid_list: @formatted_asteroid_data,
      biggest_astroid: @largest_astroid_diameter,
      total_number_of_astroids: @total_number_of_astroids
    }
    end
  end
end
