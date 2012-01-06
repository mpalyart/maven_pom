module MavenPom
  class Pom
    attr_reader :uri

    def initialize(str, uri)
      @pom = Nokogiri.XML(str)
      @uri = uri
      @dir = File.dirname(uri)
    end

    def as_json(opts = nil)
      {
        :key       => key,
        :name      => name,
        :parent    => parent,
        :packaging => packaging
      }
    end

    def to_json(*args)
      as_json.to_json(*args)
    end

    def packaging
      @pom.css("project > packaging").text
    end

    def name
      @pom.css("project > name").text.strip
    end

    def build_plugins
      @pom.css("plugins > plugin").map do |node|
        dependency_name_from(node)
      end
    end

    def parent
      parent = @pom.css("project > parent").first

      if parent
        gid = parent.css("groupId").text
        aid = parent.css("artifactId").text

        "#{gid}:#{aid}"
      end
    end

    def group_id
      gid = @pom.css("project > groupId").text
      gid = @pom.css("project > parent > groupId").text if gid.empty?

      if gid.empty?
        raise MissingGroupIdError, "could not find groupId in pom (uri=#{uri.inspect})"
      end

      gid
    end

    def artifact_id
      @pom.css("project > artifactId").text
    end

    def key
      @key ||= "#{group_id}:#{artifact_id}"
    end

    def dependencies
      @pom.css("dependencies > dependency").map do |node|
        dependency_name_from(node)
      end
    end

    def dependency_name_from(node)
      gid = node.css("groupId").text
      aid = node.css("artifactId").text

      gid = group_id if gid == "${project.groupId}" # ugh

      "#{gid}:#{aid}"
    end

  end # Pom
end # Maven
