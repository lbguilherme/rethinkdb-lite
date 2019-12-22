require "./database_file"
require "../reql/executor/datum"

module Storage
  def self.data_offset
    x = DataPage.new
    pointerof(x.@data).address - pointerof(x).address
  end

  struct Data
    getter page

    def initialize(@page : PageRef)
    end

    def read(r : DatabaseFile::Reader)
      io = DataIO.new(r, @page)
      ReQL::Datum.unserialize(io)
    end

    def write(w : DatabaseFile::Writter, obj)
      slice = ReQL::Datum.new(obj).serialize
      pos = 0
      max_size_per_page = page.size - Storage.data_offset
      page = @page
      while pos < slice.size
        count = Math.min(max_size_per_page, slice.size - pos)
        slice[pos, count].copy_to(page.pointer + Storage.data_offset, count)
        page.as_data.value.size = count.to_u32
        pos += count
        if pos < slice.size
          succ = page.as_data.value.succ
          if succ == 0
            next_page = w.alloc('D')
            page.as_data.value.succ = next_page.pos
            w.put(page)
            page = next_page
          else
            w.put(page)
            page = w.get(succ)
          end
        else
          page.as_data.value.succ = 0u32
          w.put(page)
        end
      end

      succ = page.as_data.value.succ
      truncate(w, succ) unless succ == 0
    end

    def self.create(w : DatabaseFile::Writter, obj)
      data = new(w.alloc('D'))
      data.write(w, obj)
      data.page
    end

    private def truncate(w : DatabaseFile::Writter, pos : UInt32)
      page = w.get(pos)
      succ = @page.as_data.value.succ
      truncate(w, succ) unless succ == 0
      w.del(pos)
    end

    class DataIO < IO
      def initialize(@r : DatabaseFile::Reader, @page : PageRef)
        @pos = 0
        @page_pos = 0
      end

      def read(slice : Bytes)
        pos = 0
        while pos < slice.size
          page_size = @page.as_data.value.size
          if @page_pos == page_size
            succ = @page.as_data.value.succ
            if succ != 0
              @page = @r.get(succ)
              @page_pos = 0
              next
            else
              break
            end
          end
          count = Math.min(page_size - @page_pos, slice.size - pos)
          slice[pos, count].copy_from(@page.pointer + Storage.data_offset + @page_pos, count)
          pos += count
          @pos += count
          @page_pos += count
        end
        pos
      end

      def write(slice : Bytes) : Nil
        raise "only for reading"
      end
    end
  end
end
