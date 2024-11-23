# Demo Checker Plugin

This plugin is used to check if players are recording demos or not.

## Compiling

Requires [morecolors.inc](https://github.com/DoctorMcKay/sourcemod-plugins/blob/master/scripting/include/morecolors.inc)

## Installation

1. Download the plugin from the [releases page](https://github.com/ozfortres/demo-check-plugin/releases).
2. Install the `plugins/demo_check.smx` file into your `tf/addons/sourcemod/plugins` directory.
3. Install the `translations/demo_check.phrases.txt` file into your `tf/addons/sourcemod/translations` directory.
4. Restart your server.

## Configuration

The plugin has a few cvars that can be configured:

- `sm_democheck_enabled <0/1>` - Enable or disable the plugin. Default: `1`
- `sm_democheck_onreadyup <0/1>` - Performs an additional check at ready up. Requires SoapDM to be running. Default: `0`

Additionally if your use case requires different languages or links to documentation, you can modify the `demo_check.phrases.txt` file in the `translations` directory. Currently only English is supported, and existing documentation links are for ozfortress.

## Commands

All commands are server side only.

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
