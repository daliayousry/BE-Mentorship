type Task = {
    id: number;
    title: string;
    priority: number;
    completed: boolean;
  };
  
  // 1. Return tasks sorted by priority, highest first.
  function sortByPriority(tasks: Task[]): Task[] {
    return tasks.sort((a,))
  }
  
  // 2. Return tasks excluding completed ones.
  function excludeCompleted(tasks: Task[]): Task[] {}
  
  // 3. Return tasks with priority >= minPriority.
  function filterByPriority(
    tasks: Task[],
    minPriority: number
  ): Task[] {}