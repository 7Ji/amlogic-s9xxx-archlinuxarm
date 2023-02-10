# Periodical builder
These are systemd .service and .timer units and corresponding script to build the image on a periodical schedule, the default being built every day (i.e. nightly)

## To use it
1. Copy `alarm-builder.service` and `alarm-builder.timer` to `/etc/systemd/system`
2. Edit the copied `alarm-builder.service` to reflect the actual paths and users, the following lines:
    ```
    User=YOUR_USER_NAME
    WorkingDirectory=PATH_TO_THE_PROJECT_FOLDER
    ExecStart=/bin/bash -e ABSOLUTE_PATH_TO_BUILDER.SH
    ```
    should be modified to the following if e.g. the build user is `alarm-builder` and you store the project right under its home folder:
    ```
    User=alarm-builder
    WorkingDirectory=/home/alarm-builder/amlogic-s9xxx-archlinuxarm
    ExecStart=/bin/bash -e /home/alarm-builder/amlogic-s9xxx-archlinuxarm/builder/builder.sh
    ```
3. Add environmental variables if you want to change the build behaviour.   
The variables are documented in the main `README.md` for the project itself.   
Setting them with a line `Environment='key1=value1' 'key2=value2'...` **inside the `[service]` category** if you need them.  
_E.g. Adding the following line of environment will make the builder skip `xz`ing the output tarballs and images_
    ```
    Environment='SKIP_XZ=yes`
    ```
4. Edit `sudoers` and make sure the user can use `sudo` without passwd.  
_This is dangerous as it seems, so make sure your system is secure and there's no way the user could be hacked before root. It's also up to you whether you should trust the script in this project_
    1. Run `visudo` to open the `sudoer` edittor
    2. Add a line like the following:
        ```
        alarm-builder ALL=(ALL:ALL) ALL
        ```
4. (Optional) Do a manual build of the service to test if it runs without problems
    ```
    systemctl start alarm-builder.service
    ```
5. Enable the timer and start it 
    ```
    systemctl enable --now alarm-builder.timer
    ```
