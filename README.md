# TeraProxy-Launcher

TeraProxy-Launcher is designed to be used as the simple way to start both Tera Proxy as well as Tera Launcher one after another.
It will automatically request administrator permission for the proxy and wait for it to start before starting Tera Launcher.

# Usage

Download the version you want from the Releases page and extract it.
No installation required.
It will automatically request you for the location of TeraProxy and Tera-Launcher on initial startup.

# Starting more apps

To start more than Tera Proxy before the game, open the ini file and add a new section. 
Note that apps will be executed in the order they are defined inside the ini file with the exception of [Tera] that will be always be started last.

    [UniqueSectionNameForYourApp]
    Name=Name of your app
    Path=C:\Path\To\executable.exe
    Admin=1
    Delay=200
    Find=node.exe
    Required=1

 - **Name** - This is the name of the app shown on screen when launching it
 - **Path** - The complete path to the application executable. If it's not set, you will be prompted to select the executable file
 - **Admin** - If the app requires administrator privileges to work properly, set this to 1 to start it with the proper privileges, set to 0 if it doesn't need them
 - **Delay** - Delay the execution of the app by this number of miliseconds (1000 ms = 1 second). Use this to allow the previous app to finish it's startup process
 - **Find** - If the app can take a while to start, you can specify the process name here and the startup will wait for this process to start before proceeding with the next app
 - **Required** - If you don't want Tera to start if the app fails to load, set this to 1 to stop execution if it wasn't able to start the app, otherwise set to 0.
