import { enumerateValues, HKEY, RegistryValueType } from 'registry-js'
import taskLib = require('vsts-task-lib/task');

import * as path from 'path';

export async function runBuild(): Promise<void> {

  taskLib.setResourcePath(path.join(__dirname, "task.json"));

  const aipPath: string = taskLib.getPathInput('AipPath', true, false);
  let aipBuild: string = taskLib.getInput('AipBuild');
  let aipPackageName: string = taskLib.getInput('AipPackageName');
  let aipOutputFolder: string = taskLib.getInput('AipOutputFolder');

  if (aipOutputFolder == taskLib.getVariable('BUILD_SOURCESDIRECTORY')) {
    taskLib.debug("Reset AipOutputFolder. OLD: $aipOutputFolder NEW:(empty).");
    aipOutputFolder = ""
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
  const advinstToolPath: string = getAdvinstComTool();
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

function getAdvinstPathFromReg(): string {

  // Advinst registry constants
  const advinstWowRegKeyPath: string = 'SOFTWARE\\Wow6432Node\\Caphyon\\Advanced Installer';
  const advinstRegKeyPath: string = 'SOFTWARE\\Caphyon\\Advanced Installer';
  const advinstPathRegValue: string = 'Advanced Installer Path';
  const advinstComSubPath: string = 'bin\\x86\\AdvancedInstaller.com';

  let advinstComPath: string = null;
  // Search the Advanced Installer root path in in both redirected and non-redirected hives.
  const wowRegs = enumerateValues(HKEY.HKEY_LOCAL_MACHINE, advinstWowRegKeyPath).filter(function (reg) { return reg.name === advinstPathRegValue });
  if (wowRegs.length > 0) {
    advinstComPath = path.join(wowRegs[0].data.toString(), advinstComSubPath)
  }
  // Search the Advanced Installer root path in in both redirected and non-redirected hives.
  const regs = enumerateValues(HKEY.HKEY_LOCAL_MACHINE, advinstRegKeyPath).filter(function (reg) { return reg.name === advinstPathRegValue });
  if (regs.length > 0) {
    advinstComPath = path.join(regs[0].data.toString(), advinstComSubPath)
  }

  if (taskLib.exist(advinstComPath)) {
    return advinstComPath;
  }

  return null;
}

function isAdvinstInstalled(): boolean {
  return getAdvinstPathFromReg() != null
}

function isAdvinstInPATH(): boolean {
  const { spawnSync } = require('child_process');
  const wh = spawnSync('where', ['AdvancedInstaller.com']);
  return wh.status == 0;
}

function getAdvinstComTool(): string {
  let toolPath: string = getAdvinstPathFromReg();
  if (toolPath == null && isAdvinstInPATH()) {
    toolPath = "AdvancedInstaller.com"
  }
  return toolPath;
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

function _getAgentTemp() {
  taskLib.assertAgent('2.115.0');
  let tempDirectory = taskLib.getVariable('Agent.TempDirectory');
  if (!tempDirectory) {
    throw new Error(taskLib.loc("AgentTempDirAssert"));
  }
  return tempDirectory;
}