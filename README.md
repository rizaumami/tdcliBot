# <p align="center">tdcliBot

<p align="center">**Telegram CLI based bot**


`tdcliBot` is a [Telegram](https://telegram.org/) bot based on latest [telegram-cli](https://valtman.name/telegram-cli).  

This bot currently is on a beta stage, so expect for bugs. Documentation will follow.

## How to Install  

- [Telegram-cli need a recent gcc](https://valtman.name/telegram-cli/faq) (>= v4.9), so you must have it installed on your system.  
If you're on Ubuntu, see [this page](http://askubuntu.com/questions/466651/how-do-i-use-the-latest-gcc-on-ubuntu).
- `tdcliBot` uses bot API for some tasks. Ask for a token from [@BotFather](https://t.me/BotFather).
- Clone `tdcliBot` repo and then install its requirements.
```bash
git clone https://github.com/rizaumami/tdcliBot
cd tdcliBot
./tdcliBot install
```
- Start `redis-server`, either by issuing `sudo service redis-server start`, or if on systemd, `sudo systemctl start redis-server`.
- Start `tdcliBot`.
```bash
./tdcliBot start
```

Most of `tdcliBot` commands are similar to [merbot](https://github.com/rizaumami/merbot), so you can see [@thefinemanual](https://t.me/thefinemanual) or [merbots wiki](https://github.com/rizaumami/merbot/wiki) for full merbots commands list, or by typing `!help` command on `tdcliBot`.

Please try, raise an issue, or ask for a pull request.

If you need to discuss about:
- `tdcliBot`, join [here](https://t.me/joinchat/AAAAAD9poeUnAKaTGkhVLA)
- `telegram-cli`, join [here](https://telegram.me/joinchat/AAZTvzwRgCYrDGW9MXBhfg)
- Telegram bot development, join [here](https://t.me/BotDevelopment)
