require "rest-client"
require "json"

class HeyWatch
  class InvalidResource < ArgumentError; end
  class BadRequest < RuntimeError; end
  
  URL = "https://heywatch.com"
  VERSION = "1.0.1"
  
  attr_reader :cli
  
  # Authenticate with your HeyWatch credentials
  #
  # hw = HeyWatch.new(user, passwd)
  def initialize(user, password)
    @cli = RestClient::Resource.new(URL, {:user => user, :password => password, :headers =>
      {:user_agent => "HeyWatch Ruby/#{VERSION}", :accept => "application/json"}})
      
    self
  end
  
  def inspect # :nodoc:
    "#<HeyWatch: " + account.inspect + ">"
  end
  
  # Get account information
  #
  # hw.account
  def account
    JSON.parse(@cli["/account"].get)
  end

  # Get all from a given resource.
  # Filters are optional
  #
  # hw.all :video
  # hw.all :format, :owner => true
  def all(*resource_and_filters)
    resource, filters = resource_and_filters
  
    result = JSON.parse(@cli["/#{resource}"].get)
    return result if filters.nil? or filters.empty?

    return filter_all(result, filters)
  end
  
  # Get info about a given resource and id
  #
  # hw.info :format, 31
  def info(resource, id)
    JSON.parse(@cli["/#{resource}/#{id}"].get)
  end
  
  # Count objects from a given resources.
  # Filters are optional
  #
  # hw.count :job
  # hw.count :job, :status => "error"
  def count(*resource_and_filters)
    all(*resource_and_filters).size
  end
  
  # Get the binary data of a video / encoded_video
  #
  # hw.bin :encoded_video, 12345
  def bin(resource, id, &block)
    unless [:encoded_video, :video].include?(resource.to_sym)
      raise InvalidResource, "Can't retrieve '#{resource}'"
    end
    
    @cli["/#{resource}/#{id}.bin"].head do |res, req|
      return RestClient.get(res.headers[:location], :raw_response => true, &block)
    end
  end
  
  # Generate thumbnails in the foreground or background via :async => true
  #
  # hw.jpg 12345, :start => 2
  # => thumbnail data
  #
  # hw.jpg 12345, :async => true, :number => 6, :s3_directive => "s3://accesskey:secretkey@bucket"
  # => true
  def jpg(id, params={})
    if params.delete(:async) or params.delete("async")
      @cli["/encoded_video/#{id}/thumbnails"].post(params)
      return true
    end
    
    unless params.empty?
      params = "?" + params.map{|k,v| "#{k}=#{v}"}.join("&")
    end
    @cli["/encoded_video/#{id}.jpg#{params}"].get
  rescue RestClient::BadRequest=> e
    raise BadRequest, e.http_body
  end
  
  # Create a resource with the give data
  #
  # hw.create :download, :url => "http://site.com/video.mp4", :title => "testing"
  def create(resource, data={}) 
    JSON.parse(@cli["/#{resource}"].post(data))
  rescue RestClient::BadRequest=> e
    raise BadRequest, e.http_body
  end
  
  # Update an object by giving its resource and ID
  #
  # hw.update :format, 9877, :video_bitrate => 890
  def update(resource, id, data={})
    @cli["/#{resource}/#{id}"].put(data)
    info(resource, id)
  rescue RestClient::BadRequest=> e
    raise BadRequest, e.http_body
  end
  
  # Delete a resource
  #
  # hw.delete :format, 9807
  def delete(resource, id)
    @cli["/#{resource}/#{id}"].delete
    true
  end
  
  private
  
  def filter_all(result, filters) # :nodoc:
    if filters.is_a?(Array)
      filters = Hash[*filters.map{|f| f.split("=") }.flatten]
    end
    
    filtered = []
    result.each do |r|
      if eval("true if " + filters.map{|k,v| "'#{r[k.to_s]}' =~ /#{v}/"}.join(" and "))
        filtered << r
      end
    end
    filtered
  end
end