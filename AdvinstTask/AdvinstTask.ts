import * as taskLib from 'vsts-task-lib/task';
import * as toolLib from 'vsts-task-tool-lib/tool';

import * as path from 'path';


async function run() {
  try { 
    taskLib.setResourcePath(path.join(__dirname, "task.json"));
  }
}