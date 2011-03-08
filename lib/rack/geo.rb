require 'rack/geo/version'

module Rack
  class Geo
    def initialize(app)
      @app = app
    end

    def call(env)
      position = Position.new(env["HTTP_GEO_POSITION"] || env["HTTP_X_GEO_POSITION"])
      env["geo.position"] = position if position.valid?
      @app.call(env)
    end

    class Position
      attr_accessor :latitude, :longitude, :altitude, :uncertainty, :heading, :speed

      def initialize(value=nil)
        parse! value
      end

      MATCH_LLA = /\A([+-]?[0-9\.]+);([+-]?[0-9\.]+)(?:;([+-]?[0-9\.]+))?/.freeze
      MATCH_EPU = /\sepu=([0-9\.]+)(?:\s|\z)/i.freeze
      MATCH_HDN = /\shdn=([0-9\.]+)(?:\s|\z)/i.freeze
      MATCH_SPD = /\sspd=([0-9\.]+)(?:\s|\z)/i.freeze

      # Parse Geo-Position header:
      # http://tools.ietf.org/html/draft-daviel-http-geo-header-05
      def parse!(value)
        reset!
        value = value.to_s.strip

        if lla = MATCH_LLA.match(value)
          @latitude = lla[1].to_f
          @longitude = lla[2].to_f
          @altitude = lla[3].to_f if lla[3]
        end

        if epu = MATCH_EPU.match(value)
          @uncertainty = epu[1].to_f
        end

        if hdn = MATCH_HDN.match(value)
          @heading = hdn[1].to_f
        end

        if spd = MATCH_SPD.match(value)
          @speed = spd[1].to_f
        end

        nil
      end

      def valid?
        (!latitude.nil? && latitude.respond_to?(:to_f) && (-90..90).include?(latitude.to_f)) &&
        (!longitude.nil? && longitude.respond_to?(:to_f) && (-180..180).include?(longitude.to_f)) &&
        (altitude.nil? || altitude.respond_to?(:to_f)) &&
        (uncertainty.nil? || uncertainty.respond_to?(:to_f) && uncertainty.to_f >= 0) &&
        (heading.nil? || heading.respond_to?(:to_f) && (0..360).include?(heading.to_f)) &&
        (speed.nil? || speed.respond_to?(:to_f) && speed.to_f >= 0)
      end

      def attributes
        {
          :latitude => latitude,
          :longitude => longitude,
          :altitude => altitude,
          :uncertainty => uncertainty,
          :heading => heading,
          :speed => speed,
        }
      end

      def to_http_header
        value = "%s;%s" % [latitude.to_f.to_s, longitude.to_f.to_s]
        value += ";%f" % altitude.to_f if altitude
        value += " epu=%f" % uncertainty.to_f if uncertainty
        value += " hdn=%f" % heading.to_f if heading
        value += " spd=%f" % speed.to_f if speed
        value
      end

      def self.from_http_header(value)
        self.new(value)
      end

      private

      def reset!
        @latitude = @longitude = @altitude = @uncertainty = @heading = @speed = nil
      end
    end
  end
end
