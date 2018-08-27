#  Copyright (c) 2017, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Person::Filter::Attributes < Person::Filter::Base

  MATCH = 'match'.freeze

  def initialize(attr, args)
    @attr = attr
    @args = args
  end

  def apply(scope)
    scope.where(attributes_condition)
  end

  private

  def attributes_condition
    args.map do |_k, v|
      next unless v[:value] && v[:key]

      value = Mysql2::Client.escape(v[:value].strip)
      key = Mysql2::Client.escape(v[:key])

      attribute_condition_sql(key, value, v[:constraint])

    end.join(' AND ')
  end

  def attribute_condition_sql(key, value, constraint)
    if Person.columns_hash[key].type == :integer
      integer_attribute_condition_sql(key, value)
    else
      string_attribute_condition_sql(key, value, constraint == MATCH)
    end
  end

  def string_attribute_condition_sql(key, value, match)
    value = match ? "%#{value}%" : value
    <<-SQL.strip_heredoc()
      people.#{key} LIKE '#{value}'
    SQL
  end

  def integer_attribute_condition_sql(key, value)
    <<-SQL.strip_heredoc()
      people.#{key} == #{value}
    SQL
  end
end
