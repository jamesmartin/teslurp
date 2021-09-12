require "tesla_api"
require "optparse"
require "logger"
require_relative "token_service"

def token_service
  logger = Logger.new(STDERR)
  logger.level = Logger::WARN # Keep the token service quiet unless something goes wrong
  @token_service ||= TokenService.new(
    client_id: ENV["CLIENT_ID"],
    client_secret: ENV["CLIENT_SECRET"],
    logger: logger
  )
end

def tesla_api
  @client ||= TeslaApi::Client.new(
    access_token: token_service.token
  )
end

if __FILE__ == $0
  @options = {}
  OptionParser.new do |opts|
    opts.banner = "Usage: example.rb [options]"

    opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
      @options[:verbose] = v
    end

    opts.on("-c", "--car", "Car battery/charging state") do |c|
      @options[:car] = c
    end

    opts.on("-l", "--load", "Energy Gateway load") do |l|
      @options[:load] = l
    end
  end.parse!

  def full_output?
    !@options[:verbose].nil?
  end

  def load_output?
    !@options[:load].nil?
  end

  def car_output?
    !@options[:car].nil?
  end

  car_output = []
  if full_output? || car_output?
    vehicles = tesla_api.vehicles
    return if vehicles.none?
    vehicles.each do |vehicle|
      car_output << "#{vehicle.data["display_name"]}" if full_output?
      status = "🚘#{vehicle.charge_state["battery_level"]}/#{vehicle.charge_state["charge_limit_soc"]}%"
      status += " 🔌" if vehicle.charge_state["charging_state"] == "Charging"
      car_output << status
      car_output << "---" if car_output? # Divider to make sure subsequent lines stay in the BitBar sub-menu
      actual_amps = vehicle.charge_state["charger_actual_current"]
      possible_amps = vehicle.charge_state["charger_pilot_current"]
      volts = vehicle.charge_state["charger_voltage"]
      car_output << "⚡️#{vehicle.charge_state["charger_power"]}kW (#{actual_amps}/#{possible_amps}A @ #{volts}V)"
    end
    car_output.each { |msg| puts msg }
  end
    powerwall_response = tesla_api.get("powerwalls/STE20200727-00002")["response"]
    power_reading = Array(powerwall_response["power_reading"])
    if power_reading.any?
      solar_watts = (Float(power_reading.first["solar_power"] || 0) / 1000).ceil(2)
      load_power = (Float(power_reading.first["load_power"] || 0) / 1000).ceil(2)
      grid_power = (Float(power_reading.first["grid_power"] || 0) / 1000).ceil(2)

      if full_output?
        puts "Solar: #{solar_watts}kW"
        puts "Load: #{load_power}kW"
        puts "Grid: #{grid_power}kW"
      elsif load_output?
        puts "⚡️#{(solar_watts - load_power).ceil(2)}kW"
        puts "---"
        puts "☀️ #{solar_watts}kW"
        puts "🏠 #{load_power}kW"
        puts "🏭 #{grid_power}kW"
      end
    end
end
