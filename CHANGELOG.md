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

### Advanced Installer Build Task 2.0.0

Features:
* Added support for caching Advanced Installer on the build agent prior to build. Now this extension encompasses the capabilities of [Advanced Installer Tool Installer](https://marketplace.visualstudio.com/items?itemName=caphyon.AdvancedInstallerTool)

### Advanced Installer Build Task 2.0.1

Improvements:
* Switch to the modern *azure-pipelines-task-lib* and *azure-pipelines-tool-lib* libraries.

Bugs:
* Fixed issue that caused the pipeline to fail when an Advanced Installer version was not specified.

### Advanced Installer Build Task 2.0.2

Bugs:
* *Postjobexecution* script will *not fail* on an unsupported agent OS

### Advanced Installer Build Task 2.0.3

Bugs:
* Pipeline hangs when the Advanced Installer extraction folder contains spaces

### Advanced Installer Build Task 2.0.4

Bugs:
* *Output Package Folder* field was initialized even if no user value specified. This caused Advanced Installer Build task to fail.

### Advanced Installer Build Task 2.0.5

Bugs:
* Fixed bug introduced in *2.0.4* which caused pipelines that had *Output Package Folder* set to a relative path to fail.

### AAdvanced Installer Build Task 2.0.6

Improvements:
* Disable task cleanup by setting variable _**advancedinstaller.cleanup = false**_

### Advanced Installer Build Task 2.0.7

Improvements:
* Migrate task to Node10 to avoid deprecation warning. Details [here](https://github.com/microsoft/azure-pipelines-tasks/blob/master/docs/migrateNode10.md).

### Advanced Installer Build Task 2.0.8

Improvements:
* Fix misleading documentation about the Advanced Installer vesrion. 
