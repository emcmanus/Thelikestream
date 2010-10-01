# tmp_page = Tempfile.new "thumb"     # 590 or 550' width, maintain ratio
# tmp_small = Tempfile.new "thumb"    # 100' width, maintain ratio
# tmp_thumb = Tempfile.new "thumb"    # 100' width, crop 70' height, gravity center
# tmp_square = Tempfile.new "thumb"   # 75'x75' square, crop gravity center (For use with facebook likes)
# tmp_tiny = Tempfile.new "thumb"     # 30'x30' square, cropy gravity center

class AddThumbStringsToPage < ActiveRecord::Migration
  def self.up
    change_table :pages do |t|
      t.string    :thumbnail_page
      t.string    :thumbnail_page_width
      t.string    :thumbnail_page_height
      
      # Constrained dimensions
      t.string    :thumbnail_thumb
      t.string    :thumbnail_square
      t.string    :thumbnail_tiny
    end
  end

  def self.down
    change_table :pages do |t|
      t.remove :thumbnail_page, :thumbnail_page_width, :thumbnail_page_height
      t.remove :thumbnail_thumb, :thumbnail_square, :thumbnail_tiny
    end
  end
end
