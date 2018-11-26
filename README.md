WebRTC build library
====================

Build for Windows
-----------------

1. Install prerequisites
    * Install Visual Studio 2015
    * Install [scoop](http://scoop.sh/)
    ```
    % scoop install busybox git make rsync tar xz
    % scoop reset tar
    % scoop reset xz
    ```
2. Build webrtc library
    * Open a Visual Studio 2015 Developer Command Prompt
    ``` sh
    % make
    ```

Build for Linux
---------------
1. Install prerequisites
    ```
    % cd prereqs
    % ./install-build-deps.sh
    ```
2. Build webrtc library
    ```
    % make
    ```

Build for Rasberry Pi
---------------------
1. Make sure linux compile works
2. Build arm
    ```
    % make arm
    ```

Build for mac
-------------
1. Install xcode command line tools
    ```
    % xcode-select --install
    ```
2. Build webrtc library
    ```
    % make
    ```