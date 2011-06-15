require "rest-client"
require "json"

class HeyWatch
  class InvalidResource < ArgumentError; end
  class BadRequest < RuntimeError; end
  
  VALID_RESOURCES = [:video, :encoded_video, :job, :download, :format]
  URL = "https://heywatch.com"
  VERSION = "1.0.0"
  
  attr_reader :cli
  
  def initialize(user, password)
    @cli = RestClient::Resource.new(URL, {:user => user, :password => password, :headers =>
      {:client => "HeyWatch Ruby #{VERSION}"}})
      
    self
  end
  
  def inspect
    "#<HeyWatch: " + account.inspect + ">"
  end
  
  def account
    JSON.parse(@cli["/account.json"].get)
  end

  def all(resource)
    raise_if_invalid_resource resource
    
    JSON.parse(@cli["/#{resource}.json"].get)
  end
  
  def info(resource, id)
    raise_if_invalid_resource resource
    
    JSON.parse(@cli["/#{resource}/#{id}.json"].get)
  end
  
  def bin(resource, id, &block)
    unless [:encoded_video, :video].include?(resource.to_sym)
      raise InvalidResource, "Can't retrieve '#{resource}'"
    end
    
    @cli["/#{resource}/#{id}.bin"].head do |res, req|
      return RestClient.get(res.headers[:location], :raw_response => true, &block)
    end
  end
  
  def jpg(id, params={})
    if params.delete(:async) or params.delete("async")
      @cli["/encoded_video/#{id}/thumbnails.json"].post(params)
      return true
    end
    
    unless params.empty?
      params = "?" + params.map{|k,v| "#{k}=#{v}"}.join("&")
    end
    @cli["/encoded_video/#{id}.jpg#{params}"].get
  rescue RestClient::BadRequest=> e
    raise BadRequest, e.http_body
  end
  
  def create(resource, data={})
    raise_if_invalid_resource resource
    
    JSON.parse(@cli["/#{resource}.json"].post(data))
  rescue RestClient::BadRequest=> e
    raise BadRequest, e.http_body
  end
  
  def update(resource, id, data={})
    raise_if_invalid_resource resource
    
    @cli["/#{resource}/#{id}.json"].put(data)
    info(resource, id)
  rescue RestClient::BadRequest=> e
    raise BadRequest, e.http_body
  end
  
  def delete(resource, id)
    raise_if_invalid_resource resource
    
    @cli["/#{resource}/#{id}.json"].delete
    true
  end
  
  private
  
  def raise_if_invalid_resource(resource)
    unless VALID_RESOURCES.include?(resource.to_sym)
      raise InvalidResource, "Can't find resource '#{resource}'"
    end
  end
end