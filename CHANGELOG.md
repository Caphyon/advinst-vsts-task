# ChangeLog

Changelog of Advanced Installer VSTS task.

### Advanced Installer Build Task 1.0

* First official release.

### Advanced Installer Build Task 1.2

Improvements:
* Port task to use the Powershell3 handler and VSTS task SDK.

### Advanced Installer Build Task 1.2.1

Improvements:
* Search Advanced Installer in PATH if not found on system.

### Advanced Installer Build Task 1.2.2

Bugs:
* *Output Package Folder* field was initialized even if no user value specified. This caused Advanced Installer build to fail.

### Advanced Installer Build Task 1.2.3

Improvements:
* Changed task name to avoid confusion with [Advanced Installer Tool Installer](https://marketplace.visualstudio.com/items?itemName=caphyon.AdvancedInstallerTool).
* Several cosmetic changes to the Marketplace page.

### Advanced Installer Build Task 1.2.4

Bugs:
* Stop build if the Advanced Installer task fails.

### Advanced Installer Build Task 1.2.5

Bugs:
* Removed "Build required" validation, when specifying output path or package name, as some AI projects (E.g. patch, msm) do not use builds.
