# Demo Checker Plugin
[![Demo Check Autobuild](https://github.com/ozfortress/demo_check_plugin/actions/workflows/build.yml/badge.svg)](https://github.com/ozfortress/demo_check_plugin/actions/workflows/build.yml)

This plugin is used to check if players are recording demos or not.

## Compiling

All includes and extensions are bundled with this repository. Special thanks to [Dr. McKay](https://github.com/DoctorMcKay/sourcemod-plugins/blob/master/scripting/include/morecolors.inc) and [Sapphonie](https://github.com/sapphonie/StAC-tf2) from whom I shamelessly stole morecolors.inc and SteamWorks.inc/discord.inc (plus extensions) from.

Note: Don't like Discord? You can compile without Discord by passing `NO_DISCORD=true` to spcomp.

```bash
./spcomp64 -i"/path/to/sourcemod/scripting/include" -i"/path/to/demo_check/repo/clone/scripting/include" NO_DISCORD=true "/path/to/demo_check/repo/clone/scripting/demo_check.sp" -o "/path/to/demo_check/repo/clone/plugins/demo_check_no_demo.smx"
```

## Installation

1. Download the plugin from the [releases page](https://github.com/ozfortres/demo-check-plugin/releases).
2. Install the `plugins/demo_check.smx` file or the `plugins/demo_check_no_discord.smx` file into your `tf/addons/sourcemod/plugins` directory.
3. Install the `translations/demo_check.phrases.txt` file into your `tf/addons/sourcemod/translations` directory.
4. Restart your server.

## Configuration

The plugin has a few cvars that can be configured:

- `sm_democheck_enabled <0/1>` - Enable or disable the plugin. Default: `1`
- `sm_democheck_onreadyup <0/1>` - Performs an additional check at ready up. Requires SoapDM to be running. Default: `0`
- `sm_democheck_warn <0/1>` - Set the plugin into warning only mode. Default: `0`. If enabled, players will be warned if they are not recording demos, but will not be kicked.
- `sm_democheck_announce_textfile <0/1>` - Log kicks to a text file (democheck.log). Default: `0`

Additionally if your use case requires different languages or links to documentation, you can modify the `demo_check.phrases.txt` file in the `translations` directory. Currently only English is supported, and existing documentation links are for ozfortress.

We've also included Discord Webhook support! Starting from version 1.1.0, you can now configure the plugin to send a message to a Discord webhook when a player is kicked for not recording demos. To enable this feature, you will need to set the following cvars:

- `sm_democheck_announce_discord <0/1>` - Enable or disable the Discord webhook feature. Default: `0`. This Cvar and feature is not included when compiled with NO_DISCORD=true

Additionally, modify `/tf/addons/sourcemod/configs/discord.cfg` with the following:

```cfg
"Discord"
{
    "democheck"
    {
        "url" "discord webhook url"
    }
}
```

Trust me, it'll be a riot to watch. We don't set the avatar by the way, just the message. Set the avatar and username in the webhook settings on Discord.

Starting from 1.1.0, we've also enabled silencing of the check messages. This is useful if you want to run the plugin in the background without notifying players. To enable this feature, you will need to set the following cvars:

- `sm_democheck_announce <0/1>` - Enable or disable the announce feature. Default: `1` (enabled)

Players will still be told they're being kicked, and why. But they won't be alerted if the check passed.

## Commands

All commands are server side only. Yes, they can be used with RCON, and honestly it'd be funnier that way.

- `sm_democheck <#userid>` - Check if a given player is recording demos.
- `sm_democheck_all` - Check if all players are recording demos.
- `sm_democheck_enable` - Enable the plugin.
- `sm_democheck_disable` - Disable the plugin.

## How it works

The plugin will check if the following convars are set on the client

- `ds_enable 3`
- `ds_autodelete 0`

If these convars are not set, they will be kicked from the server with a message telling them to set the convars.

At this stage, the plugin only performs this check when manually triggered, when enabled by an admin (or by the config), or when a player joins while the plugin is in it's enabled state.

## License

This project is licensed under the GNU GPL 3.0 License - see the [LICENSE](LICENSE) file for details.

Parts of this project may be licensed under different licenses. See their sources for more information.
