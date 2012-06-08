require 'spec_helper'

describe Rack::Geo do
  def setup_request(header_name="HTTP_GEO_POSITION")
    @request = Rack::MockRequest.env_for("/", header_name => @coords, :lint => true, :fatal => true)
  end

  before :each do
    @latitude, @longitude, @uncertainty = 37.0625, -95.677068, 100
    @coords = "#{@latitude};#{@longitude} epu=#{@uncertainty}"
    @app = lambda { |env| [200, {"Content-Type" => "text/plain"}, [""]] }
  end

  ["HTTP_GEO_POSITION", "HTTP_X_GEO_POSITION"].each do |header_name|
    describe "with invalid geo position header '#{header_name}'" do
      before :each do
        setup_request(header_name)
        Rack::Geo::Position.stub!(:new).and_return(mock(Rack::Geo::Position, :valid? => false))
        @status, @headers, @response = described_class.new(@app).call(@request)
      end

      it "does not assign a Rack::Geo::Position instance to env['geo.position']" do
        @request['geo.position'].should be_nil
      end
    end

    describe "with valid geo position header '#{header_name}: #{@coords}'" do
      before :each do
        setup_request(header_name)
        @status, @headers, @response = described_class.new(@app).call(@request)
      end

      it "assigns a Rack::Geo::Position instance to env['geo.position']" do
        @request['geo.position'].should be_an_instance_of(Rack::Geo::Position)
      end

      it "the Rack::Geo::Position instance should reflect the header value" do
        @request['geo.position'].latitude.should == @latitude
        @request['geo.position'].longitude.should == @longitude
        @request['geo.position'].uncertainty.should == @uncertainty
      end
    end
  end
end


describe Rack::Geo::Position do

  ZEROES = %w[0 -0 +0 0.0 -0.0 +0.0]
  LATITUDES = %w[-90 -45 0 45 +45 90 +90 45.123456789]
  LONGITUDES = %w[-180 -90 -45 0 45 +45 90 +90 180 +180 120.123456789]
  ALTITUDES = %w[-85.5 -34 0 15 1337 8848 23300.0 +23300.0]
  UNCERTAINTIES = %w[0 0.0 0.00 1.25 32.1 455 600.123, 1,114.12]
  HEADINGS = %w[0 0.0 0.00 1.25 32.1 180 359.123 360, 1,200.20]
  SPEEDS = %w[0 0.0 0.00 1.25 32.1 999 9999.99 12345.6456, 1,500.35]

  describe "#new" do
    it "creates an instance of #{described_class}" do
      instance = described_class.new
      instance.should be_an_instance_of(described_class)
    end

    it "calls #parse!" do
      class GeoPositionParseTest < described_class
        def parse!(arg)
          @parsed = arg
        end
      end

      instance = GeoPositionParseTest.new "TEST"
      instance.instance_variable_get(:@parsed).should == "TEST"
    end
  end

  describe "#from_http_header" do
    it "creates an instance of #{described_class}" do
      instance = described_class.from_http_header nil
      instance.should be_an_instance_of(described_class)
    end

    it "calls #new with supplied argument" do
      described_class.should_receive(:new).with("TEST")
      described_class.from_http_header "TEST"
    end
  end
  
  describe "instance method" do
    before :each do
      @instance = described_class.new
    end

    describe "#attributes" do
      it "returns a hash" do
        @instance.attributes.should be_an_instance_of(Hash)
      end

      it "returns a hash containing specific keys" do
        h = @instance.attributes
        [:latitude, :longitude, :altitude, :uncertainty, :heading, :speed].each do |key|
          h.should have_key(key)
        end
      end
    end

    describe "#parse!" do
      it "nil sets all attributes to nil" do
        @instance.parse! nil
        @instance.latitude.should == nil
        @instance.longitude.should == nil
        @instance.altitude.should == nil
        @instance.uncertainty.should == nil
        @instance.heading.should == nil
        @instance.speed.should == nil
      end

      it "\"0;0\" parses latitude and longitude" do
        @instance.parse! "0;0"
        @instance.latitude.should == 0.0
        @instance.longitude.should == 0.0
        @instance.altitude.should == nil
        @instance.uncertainty.should == nil
        @instance.heading.should == nil
        @instance.speed.should == nil
      end

      it "\"0;0;0\" parses latitude, longitude and altitude" do
        @instance.parse! "0;0;0"
        @instance.latitude.should == 0.0
        @instance.longitude.should == 0.0
        @instance.altitude.should == 0.0
        @instance.uncertainty.should == nil
        @instance.heading.should == nil
        @instance.speed.should == nil
      end

      ZEROES.each do |latitude|
        ZEROES.each do |longitude|
          value = "#{latitude};#{longitude}"
          it "\"#{value}\" should return a new instance with latitude == 0 and longitude == 0" do
            @instance.parse! value
            @instance.latitude.should == 0.0
            @instance.longitude.should == 0.0
          end
        end
      end

      LATITUDES.each do |latitude|
        LONGITUDES.each do |longitude|
          value = "#{latitude};#{longitude}"
          latitude_f = latitude.to_f
          longitude_f = longitude.to_f
          it "#{value} should return a new instance with latitude == #{latitude_f} and longitude == #{longitude_f}" do
            @instance.parse! value
            @instance.latitude.should == latitude_f
            @instance.longitude.should == longitude_f
          end
          
          it "#to_http_header should not mess up lat/long precision for #{value}" do
            other = described_class.new
            
            @instance.parse!(value)
            other.parse!(@instance.to_http_header)
            other.latitude.should == @instance.latitude
            other.longitude.should == @instance.longitude
          end
        end
      end

      LATITUDES.each do |latitude|
        LONGITUDES.each do |longitude|
          ALTITUDES.each do |altitude|
            value = "#{latitude};#{longitude};#{altitude}"
            latitude_f = latitude.to_f
            longitude_f = longitude.to_f
            altitude_f = altitude.to_f
            it "#{value} should return a new instance with latitude == #{latitude_f}, longitude == #{longitude_f} and altitude == #{altitude_f}" do
              @instance.parse! value
              @instance.latitude.should == latitude_f
              @instance.longitude.should == longitude_f
              @instance.altitude.should == altitude_f
            end
          end
        end
      end

      UNCERTAINTIES.each do |uncertainty|
        value = "0;0;0 epu=#{uncertainty}"
        uncertainty_f = uncertainty.gsub(',', '').to_f
        it "\"#{value}\" should return a new instance with uncertainty = #{uncertainty_f}" do
          @instance.parse! value
          @instance.uncertainty.should == uncertainty_f
        end
      end

      HEADINGS.each do |heading|
        value = "0;0;0 hdn=#{heading}"
        heading_f = heading.gsub(',', '').to_f
        it "\"#{value}\" should return a new instance with heading = #{heading_f}" do
          @instance.parse! value
          @instance.heading.should == heading_f
        end
      end

      SPEEDS.each do |speed|
        value = "0;0;0 spd=#{speed}"
        speed_f = speed.gsub(',', '').to_f
        it "\"#{value}\" should return a new instance with speed = #{speed_f}" do
          @instance.parse! value
          @instance.speed.should == speed_f
        end
      end
    end

    describe "#valid?" do
      before :each do
        @instance = described_class.new "0;0;0 epu=0 hdn=0 spd=0"
        @instance.should be_valid
      end

      it "returns false for instances initialized with no arguments" do
        described_class.new.should_not be_valid
      end

      [nil, false, [], {}, -91, 90.0001, "-90.0001", "91"].each do |latitude|
        it "returns false when latitude = #{latitude.inspect}" do
          @instance.latitude = latitude
          @instance.should_not be_valid
        end
      end

      [nil, false, [], {}, -181, 180.0001, "-180.0001", "181"].each do |longitude|
        it "returns false when longitude = #{longitude.inspect}" do
          @instance.longitude = longitude
          @instance.should_not be_valid
        end
      end

      [false, [], {}].each do |altitude|
        it "returns false when altitude = #{altitude.inspect}" do
          @instance.altitude = altitude
          @instance.should_not be_valid
        end
      end

      [false, [], {}, -1, -0.0001, "-0.0001"].each do |uncertainty|
        it "returns false when uncertainty = #{uncertainty.inspect}" do
          @instance.uncertainty = uncertainty
          @instance.should_not be_valid
        end
      end

      [false, [], {}, -1, -0.0001, 360.01, 361, "-0.0001", "360.01", "361"].each do |heading|
        it "returns false when heading = #{heading.inspect}" do
          @instance.heading = heading
          @instance.should_not be_valid
        end
      end

      [false, [], {}, -1, -0.0001, "-0.0001"].each do |speed|
        it "returns false when speed = #{speed.inspect}" do
          @instance.speed = speed
          @instance.should_not be_valid
        end
      end
    end
  end
end
