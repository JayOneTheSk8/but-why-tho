class AddCitextExtension < ActiveRecord::Migration[7.1]
  def up
    enable_extension("citext") unless extensions.include?("citext")
  end

  def down
    disable_extension("citext") if extensions.include?("citext")
  end
end
