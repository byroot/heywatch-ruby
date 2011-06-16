require "rest-client"
require "json"

class HeyWatch
  class InvalidResource < ArgumentError; end
  class BadRequest < RuntimeError; end
  
  URL = "https://heywatch.com"
  VERSION = "1.0.0"
  
  attr_reader :cli
  
  def initialize(user, password)
    @cli = RestClient::Resource.new(URL, {:user => user, :password => password, :headers =>
      {:user_agent => "HeyWatch Ruby/#{VERSION}", :accept => "application/json"}})
      
    self
  end
  
  def inspect
    "#<HeyWatch: " + account.inspect + ">"
  end
  
  def account
    JSON.parse(@cli["/account"].get)
  end

  def all(*resource_and_filters)
    resource, filters = resource_and_filters
  
    result = JSON.parse(@cli["/#{resource}"].get)
    return result if filters.nil? or filters.empty?

    return filter_all(result, filters)
  end
  
  def info(resource, id)
    JSON.parse(@cli["/#{resource}/#{id}"].get)
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
  
  def create(resource, data={}) 
    JSON.parse(@cli["/#{resource}"].post(data))
  rescue RestClient::BadRequest=> e
    raise BadRequest, e.http_body
  end
  
  def update(resource, id, data={})
    @cli["/#{resource}/#{id}"].put(data)
    info(resource, id)
  rescue RestClient::BadRequest=> e
    raise BadRequest, e.http_body
  end
  
  def delete(resource, id)
    @cli["/#{resource}/#{id}"].delete
    true
  end
  
  private
  
  def filter_all(result, filters)
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