# WatchDog-Miner-NVIDIA
Watchdog for NVIDIA miners with Telegram notifications & Logs

# **Functions:**
* Control of GPUs activity (working with Nvidia only)
* Reboot if GPUs loading is below theshold for Rig
* Maintain your logs in the Logs folder. Errors, warnings, messages regarding successful start.
* GPUs frequency, fan speed, overheat, power consumption alert and reboot.
* Taking screenshot before reboot (requires NirCMD)
* Telegram notifications in case of rig issue, not working GPUs, Rig reboot.

# **Instruction:**
1. Unpack and save files and folders where you need. Do not change the NirCMD, Config folders, and don't delete tm.ps1 file.
2. Modify the beginning of .bat file with variables set-up as per comments in .bat file.
3. Changes reboot_on variable to 0 or 1 so WatchDog will work with or without reboot of Rig 
4. Add the WatchDog to autostart upon set-up of required variables.

# **Telegram instruction (bot registration and token retrieval):**
1. Please use special Telegram bot, to create your own bot. For that please use special Telegram bot — [@BotFather](https://t.me/botfather).
2. In the Chat with @BotFather Enter command /start and follow instructions.
3. Use comment /newbot - create name of your bot. @BotFather will return the name which you can add to your contacts. You may add avatar and description using @BotFather commands.
4. Check your new bot token is working - using the link https://api.telegram.org/bot12345678:dg65gf46rd-4gdrgdhJGukuhlUWl/getMe. In the link the example of token sused, please change to your own, received from @BotFather.
5. Add the received token to Config/cfg.ini file
6. Receive Chat_ID for your bot. Look to the [instruction on YouTube](https://www.youtube.com/watch?v=2jdsvSKVXNs)
7. Use the URL https://api.telegram.org/bot12345678:dg65gf46rd-4gdrgdhJGukuhlUWl/getUpdates. But update the value after "bot" with the token you've received before. You should receive the message, where Chad_ID will be provided.
8. Add the received Chat_ID to cfg.ini

# **Requirements:**
1. Windows 10 x64 (May not work on others) or Windows 7
2. MS Windows PowerShell installed.
3. Right click on the window of CMD prompt, then select “Properties” and remove the tick for “Quick Edit”.
