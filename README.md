# <p align="center">tdcliBot

<p align="center"><img src="https://raw.githubusercontent.com/wiki/rizaumami/tdcliBot/_images/tdcli-round.png" width="384" alt="tdcliBot" title="tdcliBot">

### <p align="center">A multipurpose telegram-cli based bot

`tdcliBot` is a [Telegram](https://telegram.org/) bot based on latest [telegram-cli](https://valtman.name/telegram-cli).  

This bot currently is on a beta stage, so expect for bugs.  
See [wiki](https://github.com/rizaumami/tdcliBot/wiki) for documentation.

## How to Install  

- [Telegram-cli need a recent gcc](https://valtman.name/telegram-cli/faq) (>= v4.9), so you must have it installed on your system.  
If you're on Ubuntu, see [this page](http://askubuntu.com/questions/466651/how-do-i-use-the-latest-gcc-on-ubuntu).
- `tdcliBot` uses bot API for some tasks. Ask for a token to [@BotFather](https://t.me/BotFather).
- Clone `tdcliBot` repo and then install its requirements.

    ```bash
    git clone https://github.com/rizaumami/tdcliBot
    cd tdcliBot
    ./tdcliBot install
    ```

- Start `redis-server`, either by issuing:

    ```bash
    sudo service redis-server start
    ```
    
    Or if you're on a systemd system:
    
    ```bash
    sudo systemctl start redis-server
    ```
    
- Start `tdcliBot`.

    ```bash
    ./tdcliBot start
    ```

Type `!help` or `!help <plugin_name>` command on `tdcliBot` to see how to use the plugins.

Please try, raise an issue, or ask for a pull request.

If you need to discuss about:
- `tdcliBot`, join [here](https://t.me/joinchat/AAAAAD9poeUnAKaTGkhVLA)
- `telegram-cli`, join [here](https://telegram.me/joinchat/AAZTvzwRgCYrDGW9MXBhfg)
- Telegram bot development, join [here](https://t.me/BotDevelopment)
