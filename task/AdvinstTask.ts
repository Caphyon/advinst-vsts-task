import * as taskLib from 'azure-pipelines-task-lib/task';
import * as path from 'path';
import { runBuild } from './AdvinstBuilder';

async function run() {
  try {
    taskLib.setResourcePath(path.join(__dirname, "task.json"));

    if (taskLib.osType() != 'Windows_NT')
      throw new Error(taskLib.loc("AI_UnsupportedOS"));

    await runBuild();
  }
  catch (error) {
    taskLib.setResult(taskLib.TaskResult.Failed, error.message);
  }
}

run();
