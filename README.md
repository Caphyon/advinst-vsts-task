# Advanced Installer

Businesses around the globe, large and small, save hundreds of hours and thousands of dollars by taking advantage of the expert knowledge built into Advanced Installer to create Windows Installer packages and patches for their products.

# Requirements

This plugin requires [Advanced Installer](http://www.advancedinstaller.com/) to perform the build. Depending on your platform, there are several deployment options:
* Team Services 
  - Use [Advanced Installer Tool Installer](https://marketplace.visualstudio.com/items?itemName=caphyon.AdvancedInstallerTool)
* Team Foundation Server 
  +  Use [Advanced Installer Tool Installer](https://marketplace.visualstudio.com/items?itemName=caphyon.AdvancedInstallerTool). This support is available beginning with TFS 2018.
  + Manually [download](http://www.advancedinstaller.com/download.html) and install Advanced Installer on the build host machine. 

# How to use 

The AI Build Task allows you to create a custom build step for TFS and VSTS.

![Add Tool](images/tool-add.png)

![Add Task](images/task-add.png)

![Configure Tool Installer](images/tool-configure.png)

![Configure Build Task](images/task-configure.png)