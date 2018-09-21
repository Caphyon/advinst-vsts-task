import { enumerateValues, HKEY, RegistryValueType } from 'registry-js'

export async function runBuild(): Promise<void> {
}

export function getAdvinstPathReg(): string {

  // Advinst registry constants
  const advinstWowRegKeyPath: string = 'SOFTWARE\\Wow6432Node\\Caphyon\\Advanced Installer';
  const advinstRegKeyPath: string = 'SOFTWARE\\Caphyon\\Advanced Installer';
  const advinstPathRegValue: string = 'Advanced Installer Path';
  //const advinstBinFolder: string = 'bin\\x86\\AdvancedInstaller.com';
  //const advinstTool: string = 'AdvancedInstaller.com';

  // Search the Advanced Installer root path in in both redirected and non-redirected hives.
  const wowRegs = enumerateValues(HKEY.HKEY_LOCAL_MACHINE, advinstWowRegKeyPath).filter(function (reg) { return reg.name === advinstPathRegValue });
  if (wowRegs.length > 0) {
    return wowRegs[0].data.toString();
  }

  // Search the Advanced Installer root path in in both redirected and non-redirected hives.
  const regs = enumerateValues(HKEY.HKEY_LOCAL_MACHINE, advinstRegKeyPath).filter(function (reg) { reg.name === advinstPathRegValue });
  if (regs.length > 0) {
    return regs[0].data.toString();
  }

  return null;
}

console.log(getAdvinstPathReg());