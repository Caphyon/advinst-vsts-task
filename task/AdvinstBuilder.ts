import { getAdvinstComTool, _getAgentTemp } from './AdvinstTool';
import * as taskLib from 'azure-pipelines-task-lib/task';

import * as path from 'path';

export async function runBuild(): Promise<void> {
  
  const aipPath: string = taskLib.getPathInput('AipPath', true, false);
  let aipBuild: string = taskLib.getInput('AipBuild');
  let aipPackageName: string = taskLib.getInput('AipPackageName');
  let aipOutputFolder: string = taskLib.getPathInput('AipOutputFolder', false, false);

  if (!taskLib.filePathSupplied('AipOutputFolder')) {
    taskLib.debug("Reset AipOutputFolder. OLD: $aipOutputFolder NEW:(empty).");
    aipOutputFolder = "";
  }

  const aipExtraCommands: string[] = taskLib.getDelimitedInput('AipExtraCommands', '\r\n');
  const aipResetDigSign: boolean = taskLib.getBoolInput('AipResetDigSign');

  // Log input parameters
  if (aipBuild == null) {
    aipBuild = '';
  }
  taskLib.debug(taskLib.loc("AI_StartTaskLog"));
  taskLib.debug("aipPath = " + aipPath);
  taskLib.debug("aipBuild  = " + aipBuild);
  taskLib.debug("aipPackageName = " + aipPackageName);
  taskLib.debug("aipOutputFolder = " + aipOutputFolder);
  taskLib.debug("aipExtraCommands = " + aipExtraCommands);
  taskLib.debug("aipResetDigSign = " + aipResetDigSign);

  // Validate "aipPath" input parameter.
  taskLib.checkPath(aipPath, aipPath);

  // Validate advinst tool path
  const advinstToolPath: string = await getAdvinstComTool();
  if (null == advinstToolPath) {
    throw new Error(taskLib.loc("AI_AdvinstNotFoundErr"));
  }

  // Compute the advinst commands
  let advinstCommands: string[] = [];
  if (aipPackageName) {
    advinstCommands.push(`SetPackageName \"${aipPackageName}\" -buildname \"${aipBuild}\"`);
  }

  if (aipOutputFolder) {
    advinstCommands.push(`SetOutputLocation -path \"${aipOutputFolder}\" -buildname \"${aipBuild}\"`);
  }

  if (aipResetDigSign) {
    advinstCommands.push('ResetSig');
  }

  if (aipExtraCommands.length > 0) {
    advinstCommands = advinstCommands.concat(aipExtraCommands);
  }

  advinstCommands.push(aipBuild ? `Build -buildslist \"${aipBuild}\"` : `Build`);

  //Execute the commands
  try {
    var commandsFilePath = getCommandsFile(advinstCommands);
    const advinstCmdLineArgs: string[] = ['/execute', `${aipPath}`, `${commandsFilePath}`];
    let result = taskLib.execSync(advinstToolPath, advinstCmdLineArgs);
    if (result.code != 0) {
      throw new Error(taskLib.loc("AI_ExecFailedErr", result.stdout));
    }
  }
  finally {
    if (commandsFilePath) {
      taskLib.rmRF(commandsFilePath);
    }
  }
}

function getCommandsFile(advinstCommands: string[]): string {
  let agentTempFolder: string = _getAgentTemp();
  const commandsFilePath = path.join(agentTempFolder, taskLib.getVariable('Build.BuildId') + '.aic');
  taskLib.debug("Commands file path: " + commandsFilePath);

  let commandFileContent: string[] = [';aic;'];
  commandFileContent = commandFileContent.concat(advinstCommands);
  taskLib.debug(commandFileContent.join('|'));
  taskLib.writeFile(commandsFilePath, commandFileContent.join('\r\n'));
  return commandsFilePath;
}
