# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Pdf::Participation
  class Section
    include ActionView::Helpers::TranslationHelper
    include ActionView::Helpers::TextHelper
    include StandardHelper

    attr_reader :pdf, :participation

    class_attribute :model_class

    delegate :bounds, :bounding_box, :table,
             :text, :cursor,  :font_size, :text_box,
             :fill_and_stroke_rectangle, :fill_color,
             :image, to: :pdf

    delegate :event, :person, :application, to: :participation


    def initialize(pdf, participation)
      @pdf = pdf
      @participation = participation
      @virtual_path = 'event.participations.print' #  to use t('.key')
    end

    private

    def first_page_section
      bounding_box([0, cursor], width: bounds.width, height: section_size) do
        yield
        stroke_bounds
      end
    end

    def render_section(section_class)
      section_class.new(pdf, participation).render
    end

    def with_settings(opts = {})
      before = opts.map { |key, _value| [key, pdf.send(key)] }
      opts.each { |key, value| pdf.send(:"#{key}=", value) }
      yield
      before.each { |key, value| pdf.send(:"#{key}=", value) }
    end

    # third_of_height
    def section_size
      ((bounds.height - 60) / 3) + 3
    end

    def render_boxed(left, right, offset = 0)
      y = cursor
      gutter = 10
      width = (bounds.width / 2) - (gutter / 2)

      bounding_box([0 + offset, y], width: width - offset) { left.call }
      bounding_box([width + gutter + offset, y], width: width - offset) { right.call }
    end

    def shrinking_text_box(text, opts = {})
      pdf.text_box(text, opts.merge(overflow: :shrink_to_fit))
    end

    def stroke_bounds
      # pdf.stroke_bounds if Export::Pdf::Participation::Runner.stroke_bounds
    end

    def text(*args)
      options = args.extract_options!
      pdf.text args.join(' '), options
    end

    def move_down_line(line = 10)
      pdf.move_down(line)
    end

    def heading
      font_size(11) { yield }
    end

    def labeled_attr(attr, model = nil)
      model ||= send(self.class.to_s.demodulize.downcase.to_sym)
      value = model.send(attr)
      text [model.class.human_attribute_name(attr), f(value)].join(': ') if value.present?
    end

    def human_event_name
      event.class.model_name.human
    end

    def human_participant_name
      ::Event::Role::Participant.model_name.human
    end

    def human_attribute_name(attr, model)
      model.class.human_attribute_name(attr)
    end

    def event_with_kind?
      event.class.used_attributes.include?(:kind_id)
    end
  end
end
