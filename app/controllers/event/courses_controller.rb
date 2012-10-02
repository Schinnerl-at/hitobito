class Event::CoursesController < EventsController
  self.nesting_optional = true
  helper_method :courses_by_kinds
  decorates :events

  class << self
    def model_class
      Event::Course
    end
  end

  private
  def list_entries
    @year = params[:year].to_i > 0 ? params[:year].to_i : Date.today.year
    @years = (@year-3...@year+3)
    super.in_year(@year)
  end

  def courses_by_kinds
    entries.group_by { |entry| entry.kind.label }
  end

end
