module Cloudwatch
  module Sender
    class Base
      attr_reader :influxdb, :metric_prefix

      def initialize(options, metric_prefix)
        @metric_prefix = metric_prefix
        @influxdb = InfluxDB::Client.new options['influx_database'],
          username: options['influx_username'],
          password: options['influx_password'],
          use_ssl: options['influx_ssl'] || false,
          verify_ssl: options['influx_verify_ssl'] || false,
          ssl_ca_cert: options['influx_ssl_ca_cert'] || false,
          host: options['influx_host'] || false
      end

      def write_data(data)
        if ENV['TEST'] =~ /(true|t|yes|y|1)$/i
          data = data.merge(series: metric_prefix)
          data = data.is_a?(Array) ? data : [data]
          puts(data.map do |point|
            InfluxDB::PointValue.new(point).dump
          end.join("\n".freeze))
        else
          influxdb.write_point(metric_prefix, data)
        end
      end
    end
  end
end
