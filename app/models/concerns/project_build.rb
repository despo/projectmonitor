module ProjectBuild extend ActiveSupport::Concern

  def build_status_url
    raise NotImplementedError, "Must implement build_status_url in subclasses"
  end

  def current_build_url
  end

  def green?
    online? && status.success?
  end

  def yellow?
    online? && !red? && !green?
  end

  def red?
    online? && latest_status.try(:success?) == false
  end

  def status_in_words
    if red?
      'failure'
    elsif green?
      'success'
    elsif yellow?
      'indeterminate'
    else
      'offline'
    end
  end

  def color
    return "white" unless online?
    return "green" if green?
    return "red" if red?
    return "yellow" if yellow?
  end

  def last_green
    @last_green ||= recent_statuses.green.first
  end

  def red_since
    breaking_build.try(:published_at)
  end

  def red_build_count
    return 0 if breaking_build.nil? || !online?
    statuses.where(success: false).where("id >= ?", breaking_build.id).count
  end

  def breaking_build
    @breaking_build ||= if last_green.nil?
                          recent_statuses.red.last
                        else
                          recent_statuses.red.where(["build_id > ?", last_green.build_id]).first
                        end
  end

end
