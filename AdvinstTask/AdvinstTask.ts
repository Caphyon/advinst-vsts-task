import * as taskLib from 'vsts-task-lib/task';

import * as path from 'path';
import { runBuild } from './AdvinstBuilder';
import { runAquireAdvinst } from './AdvinstTool';


async function run() {
  try {
    taskLib.setResourcePath(path.join(__dirname, "task.json"));

    if (taskLib.osType() != 'Windows_NT')
      throw new Error(taskLib.loc("AI_UnsupportedOS"));

    await runAcquireAdvinst();
    await runBuild();

  }
  catch (error) {
    taskLib.setResult(taskLib.TaskResult.Failed, error.message);
  }
}

run();