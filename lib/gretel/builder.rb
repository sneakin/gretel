module Gretel
  
  def self.new(*args)
    Builder.new(*args)
  end
  
  # The BreadcrumbTrail is responsible for building a breadcrumb.  This
  # class specializes in extracting paths from the nested URLs.
  #
  # The heavy lifting of extracting an object is delegated to the ModelExtractor.
  #
  class Builder
    extend Forwardable
    def_delegator :model_extractor, :extract_from_path, :extract_model_from_path
    attr_reader :request_path, :separator, :dom_id

    def initialize(request_path = nil, options = {})

      @request_path = request_path
      @separator = options[:separator] || '&raquo;'
      @dom_id = options[:dom_id] || 'breadcrumb_trail'
      @skip_index = options[:skip_index]
      @skip_home = !options[:home]
      @reverse = options[:reverse]
      @prefix = options[:prefix]
      @prefix_separator = options[:prefix_separator] || ': '
      @skip_resource = options[:skip_resource]
      @max_depth = options[:max_depth]
    end

    def to_s
      levels = request_path.split('?')[0].split('/')
      levels.delete_at(0)
      levels.pop if @skip_resource

      links = Array.new
      links << "<a href='/'>home</a>" unless @skip_home

      levels.each_with_index do |level, index|
        href = File.join("/", levels[0..index].join('/'))
        text = extract_model_from_path(href)
        next if @skip_index && text.nil? # && level != levels.last

        text ||= level.downcase.gsub('_', ' ').titleize

        if href == request_path
          links << text.to_s
        else
          links << %(<a href="#{href}">#{text.to_s}</a>)
        end
      end

      links.reverse! if @reverse
      links = links.collect_with_index do |link, index|
        link = "#{@prefix}#{@prefix_separator}#{link}" if index == 0 && @prefix
        link = "<li class=\"item-#{index}\">#{link}</li>"
      end
      # links.unshift("<li class=\"item-prefix\">#{@prefix}</li>") if @prefix
      links = links[0, @max_depth] if @max_depth

      %(
      <div id="#{dom_id}">
      <ul>#{links.join}</ul>
      </div>
      )
    end

    protected
    def extract_text_and_href(text, href_elements)
    end

    def model_extractor
      ModelExtractor
    end
  end
end
