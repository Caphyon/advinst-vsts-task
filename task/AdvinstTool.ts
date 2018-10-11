import * as taskLib from 'vsts-task-lib/task';
import * as toolLib from 'vsts-task-tool-lib/tool';

import * as path from 'path';
import * as semvish from 'semvish';
import * as cmpVer from 'compare-ver';
var fileInfo = require('winfileinfo/winfileinfo.node');

const advinstToolId: string = 'advinst';
const advinstToolArch: string = 'x86';
const advinstToolSubPath: string = 'bin\\x86';
const advinstToolCmdLineUtility: string = 'AdvancedInstaller.com';
const advinstToolExecutable: string = 'advinst.exe';
const advinstMSBuildTargetsVar: string = 'AdvancedInstallerMSBuildTargets';
const advinstToolRootVar: string = 'AdvancedInstallerRoot';
const advinstMSBuildTargetsSubPath: string = 'ProgramFilesFolder\\MSBuild\\Caphyon\\Advanced Installer';
const advinstDownloadUrlVar: string = 'advancedinstaller.url';
const advinstLicenseSubPath: string = 'Caphyon\\Advanced Installer\\license80.dat';
const advinstRegVersionSwitch: string = '14.6';

export async function runAcquireAdvinst() {
  try {
    taskLib.setResourcePath(path.join(__dirname, "task.json"));

    let version: string = taskLib.getInput('advinstVersion', true);
    let license: string = taskLib.getInput('advinstLicense', false);
    await getAdvinst(version, license);
  }
  catch (error) {
    taskLib.setResult(taskLib.TaskResult.Failed, error.message);
  }
}

async function getAdvinst(version: string, license: string): Promise<void> {

  if (!semvish.valid(version))
    throw Error(taskLib.loc("AI_InvalidVersionFormat", version));

  let cachedToolRoot: string;
  //Verify if this version of advinst was already installed.
  cachedToolRoot = _getLocalTool(semvish.clean(version));

  if (!cachedToolRoot) {
    console.log(taskLib.loc("AI_InstallNewTool"));
    //Extract advinst.msi and cache the content.
    cachedToolRoot = await acquireAdvinst(version);
  }
  else {
    console.log(taskLib.loc("AI_UseCachedTool", cachedToolRoot));
  }

  let msBuildTargetsPath: string = path.join(cachedToolRoot, advinstMSBuildTargetsSubPath);
  //Compute the actual AdvancedInstaller.com folder
  let advinstBinRoot: string = path.join(cachedToolRoot, advinstToolSubPath);
  //Debug traces
  taskLib.debug('cachedToolRoot = ' + cachedToolRoot);
  taskLib.debug('advinstBinRoot = ' + advinstBinRoot);
  taskLib.debug('msBuildTargetsPath = ' + msBuildTargetsPath);

  //Register advinst if a license key was provided
  await registerAdvinst(advinstBinRoot, license);
  //Add the advinst folder to PATH
  toolLib.prependPath(advinstBinRoot);

  //Set the environment variables that will be used by Advanced Installer tasks later on.
  taskLib.setVariable(advinstMSBuildTargetsVar, msBuildTargetsPath);
  taskLib.setVariable(advinstToolRootVar, cachedToolRoot);
}

async function registerAdvinst(toolRoot: string, license: string): Promise<void> {
  if (!license)
    return;

  console.log(taskLib.loc("AI_RegisterTool"))

  let toolVersion: string = fileInfo.getFileVersion(path.join(toolRoot, advinstToolExecutable));
  let registrationCmd: string = "/RegisterCI";
  if (cmpVer.lt(advinstRegVersionSwitch, toolVersion) < 0) {
    registrationCmd = "/Register";
  }

  let execResult = taskLib.execSync(path.join(toolRoot, advinstToolCmdLineUtility), [registrationCmd, license]);
  if (execResult.code != 0) {
    throw new Error(taskLib.loc("AI_RegisterToolFailed", execResult.stdout));
  }
  let licensePath = path.join(taskLib.getVariable('ProgramData'), advinstLicenseSubPath);
  taskLib.checkPath(licensePath, taskLib.loc("AI_AdvinstLicenseFile"));
}

async function acquireAdvinst(version: string): Promise<string> {

  let advinstDownloadPath: string = await _downloadAdvinst(version);
  if (!taskLib.exist(advinstDownloadPath)) {
    throw new Error(taskLib.loc("AI_DownloadToolFailed"));
  }

  let advinstToolRoot = await _extractAdvinst(advinstDownloadPath);
  if (!taskLib.exist(advinstToolRoot)) {
    throw new Error(taskLib.loc("AI_ExtractToolFailed"));
  }

  console.log(taskLib.loc("AI_CacheTool"));
  let cachedToolPath: string = await toolLib.cacheDir(advinstToolRoot, advinstToolId,
    semvish.clean(version), advinstToolArch);
  console.log(taskLib.loc("AI_CacheToolSuccess", version));

  return cachedToolPath;
}

//
// Helper methods
//
function _getLocalTool(version: string) {
  console.log(taskLib.loc("AI_CheckToolCache"));
  return toolLib.findLocalTool(advinstToolId, version, advinstToolArch);
}

async function _downloadAdvinst(version: string): Promise<string> {
  let advinstDownloadUrl: string = taskLib.getVariable(advinstDownloadUrlVar);
  if (!advinstDownloadUrl)
    advinstDownloadUrl = 'https://www.advancedinstaller.com/downloads/' + version + '/advinst.msi';

  console.log(taskLib.loc("AI_DownloadTool", advinstDownloadUrl));
  return toolLib.downloadTool(advinstDownloadUrl);
}

async function _extractAdvinst(sourceMsi: string): Promise<string> {
  console.log(taskLib.loc("AI_ExtractTool"));

  // Ensure the c:\windows\installer folder exists. MSIEXEC will fail on some clients (E.g. Hosted VS2017)
  // due to the lack of this folder.

  let windowsInstallerFolder = path.join(taskLib.getVariable('windir'), 'Installer');
  if (!taskLib.exist(windowsInstallerFolder)) {
    taskLib.debug(taskLib.loc("AI_CreateInstallerFolder"))
    taskLib.mkdirP(windowsInstallerFolder);
  }

  let advinstWorkFolder = path.join(_getAgentTemp(), 'AdvancedInstaller');
  let msiExtractionPath: string = path.join(advinstWorkFolder, 'resources');
  // Create the work folder, otherwise msiexec will fail because of the log path.
  if (!taskLib.exist(advinstWorkFolder))
    taskLib.mkdirP(advinstWorkFolder);
  let msiLogPath: string = path.join(advinstWorkFolder, 'advinst_install.log');

  let msiexecArguments: string[] = ['/a', sourceMsi, 'TARGETDIR=' + msiExtractionPath, '/qn', '/l*v', msiLogPath];

  let exitCode = taskLib.execSync('msiexec.exe', msiexecArguments).code;
  if (exitCode != 0) {
    taskLib.command('task.uploadfile', {}, msiLogPath);
    return '';
  }
  return msiExtractionPath;
}

function _getAgentTemp() {
  taskLib.assertAgent('2.115.0');
  let tempDirectory = taskLib.getVariable('Agent.TempDirectory');
  if (!tempDirectory) {
    throw new Error(taskLib.loc("AI_AgentTempDirAssert"));
  }
  return tempDirectory;
}