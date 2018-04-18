module Cloudwatch
  module Sender
    module Fetcher
      class ElastiCache
        attr_reader :cloudwatch, :sender

        def initialize(cloudwatch, sender)
          @cloudwatch = cloudwatch
          @sender = sender
        end

        START_TIME = 240

        def metrics(component_meta, metric)
          params = {
            namespace: component_meta['namespace'],
            metric_name: metric['name'],
            dimensions: [{ name: 'CacheClusterId', value: component_meta['cache_cluster'] }],
            start_time: Time.now - START_TIME,
            end_time: Time.now,
            period: 30,
            statistics: metric['statistics'],
            unit: metric['unit']
          }
          resp = cloudwatch.get_metric_statistics(params)
          name = component_meta['namespace'].downcase
          name_metrics(resp, name, metric['statistics'], component_meta['cache_cluster'])
        end

        private

        def name_metrics(resp, name, statistics, queue_name)
          resp.data['datapoints'].each do |data|
            time = data['timestamp'].to_i
            check_statistics(name, resp.data['label'], statistics, time, data, queue_name)
          end
        end

        def check_statistics(name, label, statistics, time, data, cluster_name)
          statistics.each do |stat|
            data = {
              :tags      => { 'namespace' => name, 'redis_cluster' => cluster_name },
              :timestamp => time,
              :values    => { label.downcase => data[stat.downcase] }
            }

            sender.write_data(data)
          end
        end
      end
    end
  end
end
