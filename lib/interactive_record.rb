require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

    def initialize(attributes={})
        attributes.each do |key, value|
            self.send("#{key}=", value)
        end
    end

    def self.table_name
        self.to_s.downcase.pluralize
    end

    def self.column_names
        sql = <<-SQL
        PRAGMA table_info(#{table_name})
        SQL

        DB[:conn].execute(sql).map do |row|
            row["name"]
        end
    end

    def self.find_by_name(name)
        sql = <<-SQL
        SELECT * FROM #{table_name}
        WHERE name = "#{name}";
        SQL

        DB[:conn].execute(sql)
    end

    def self.find_by(attr)
        sql = <<-SQL
        SELECT * FROM #{table_name}
        WHERE #{attr.keys.first.to_s} =
        "#{attr.values.first}";
        SQL

        DB[:conn].execute(sql)
    end

    def table_name_for_insert
        self.class.table_name
    end

    def col_names_for_insert
        self.class.column_names.delete_if{|name| name == "id"}.join(", ")
    end

    def values_for_insert
        values = []
        self.class.column_names.each do |c_name|
            values << "'#{send(c_name)}'" unless send(c_name).nil?
        end
        values.join(", ")
    end

    def save
        sql = <<-SQL
        INSERT INTO #{table_name_for_insert} (#{col_names_for_insert})
        VALUES (#{values_for_insert});
        SQL
        
        DB[:conn].execute(sql)
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert};")[0][0]
    end
end