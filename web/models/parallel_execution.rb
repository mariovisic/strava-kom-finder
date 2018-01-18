class ParallelExecution
  def self.perform(collection, &block)
    pool = Concurrent::ThreadPoolExecutor.new(
      min_threads: 0,
      max_threads: 20,
      max_queue: 0 # unbounded work queue
    )
    collection.each { |elem| pool.post(elem, block) { |data, blk| blk.(data) } }
    while (pool.running? && pool.scheduled_task_count > pool.completed_task_count)
      sleep 0.05
    end
    pool.shutdown
    pool.wait_for_termination
  end
end
