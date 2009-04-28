class Starling
  def stats
     raise MemCacheError, "No active servers" unless active?
     server_stats = {}

     @servers.each do |server|
       sock = server.socket
       raise MemCacheError, "No connection to server" if sock.nil?

       value = nil
       begin
         sock.write "stats\r\n"
         stats = {}
         while line = sock.gets do
           break if line == "END\r\n"
           if line =~ /^STAT/ then
             stat, name, value = line.split
             stats[name] = case name
                           when 'version'
                             value
                           when 'rusage_user', 'rusage_system' then
                             seconds, microseconds = value.split(/:/, 2)
                             microseconds ||= 0
                             Float(seconds) + (Float(microseconds) / 1_000_000)
                           else
                             if value =~ /^\d+$/ then
                               value.to_i
                             else
                               value
                             end
                           end
           end
         end
         server_stats["#{server.host}:#{server.port}"] = stats
       rescue SocketError, SystemCallError, IOError => err
         puts err.inspect
         server.close
         raise MemCacheError, err.message
       end
     end

     server_stats
   end

   ##
   # returns the number of items in +queue+. If +queue+ is +:all+, a hash of all
   # queue sizes will be returned.

   def sizeof(queue, statistics = nil)
     statistics ||= stats

     if queue == :all
       queue_sizes = {}
       available_queues(statistics).each do |queue|
         queue_sizes[queue] = sizeof(queue, statistics)
       end
       return queue_sizes
     end

     statistics.inject(0) { |m,(k,v)| m + v["queue_#{make_cache_key(queue)}_items"].to_i }
   end
   
   def queue_names
     return available_queues
   end
end