# macOS 27 upgrade research

Checked on 2026-09-21. This report records upstream compatibility evidence for
the Mac configuration. It does not establish that activation or every application
will work after an OS upgrade. No system settings, packages, or configuration
files were changed for this research.

## Assessment

No confirmed dotfiles blocker was found. Both the full Darwin system derivation
and the standalone `michael@macbook` Home Manager activation derivation evaluate
successfully, with no configuration warnings or failed assertions. This does not
exercise activation on macOS 27 or GUI applications.

CleanShot should be updated before upgrading. Other GUI integrations need
runtime verification. The nix-darwin report initially appeared relevant because
it starts from macOS 26.6.2, but its comments identify `mac-app-util` as the cause
and report success after removing it. This repository's flake and lockfile do not
include `mac-app-util`, so that report is not an identified blocker here.
[Resolution comment](https://github.com/nix-darwin/nix-darwin/issues/1866#issuecomment-5717202212).

Local audit evidence supplied by the main review: MacBookPro18,1 running
macOS 26.6.2, Command Line Tools 26.6.0, Nix 2.31.5, Homebrew 6.0.22,
Nix daemon running, and `/nix` APFS volume mounted. Successful evaluation on
this machine does not guarantee that the next OS preserves all runtime behavior.
`darwin/system.nix` uses numeric `AppleSymbolicHotKeys` IDs, Dock and Spaces
defaults, and System Events appearance settings. Their effect on macOS 27 has
not been tested by this audit.

Apple confirms the name macOS 27 Golden Gate and supports Apple silicon Macs.
Apple's product page gives September 14 as its availability date. This is a
released OS as of this report's date.
[Apple upgrade instructions](https://support.apple.com/en-us/127455),
[Apple compatibility list](https://support.apple.com/en-ca/127255),
[Apple product page](https://www.apple.com/uk/os/macos/).

## Package and configuration infrastructure

| Component | Evidence | Implication for this repository |
| --- | --- | --- |
| Homebrew | Its support policy lists Golden Gate on Apple silicon among supported OS versions. The same policy explicitly classifies installations managed by Nix as Tier 3. | The OS itself is supported, but this repository's nix-homebrew integration does not qualify for Homebrew's Tier 1 guarantees. [Support policy](https://docs.brew.sh/Support-Tiers). |
| nix-darwin | Issue 1866 reports an activation failure after upgrading from 26.6.2 to 27. The reporter later confirms that removing `mac-app-util` resolves it. | This flake does not include that input. Do not treat the initial report as a blocker for this repository. [Resolution](https://github.com/nix-darwin/nix-darwin/issues/1866#issuecomment-5717202212). |
| Nixpkgs GUI packages | Tracking issue 559515 describes macOS 27 app-data permission changes affecting some repackaged applications. It identifies Firefox and Brave fixes and says Chrome and the Nixpkgs Discord package are unaffected. | This is evidence of package-specific changes, not a general Nix failure. Chrome and Discord here are Homebrew casks, so the reported Nix wrapper fixes should not be applied to them. [Tracking issue](https://github.com/NixOS/nixpkgs/issues/559515). |

The checked-in lockfile pins nix-darwin to
`ebec37af18215214173c98cf6356d0aca24a2585`, dated 2026-02-26, on
`nix-darwin-25.11`. It pins Nixpkgs to
`0968519e14f7aa7d3e9b389682bd74d2b51c8ce8`, dated 2026-09-03, and
nix-homebrew to `09a921d0181146cf6163ec2cc1db7b6fd539a885`, dated 2026-09-09.
Homebrew core and cask inputs are dated September 15.
These dates come from `flake.lock`; they do not themselves establish
compatibility or require an update. No explicit macOS 27 support guarantee for
this exact pinned combination was found in the upstream material inspected.

## Applications with relevant evidence

| Application | Evidence as of this review | What still needs checking |
| --- | --- | --- |
| Tailscale and Chrome | Open issue 21330 reports slow Chromium DNS lookups and `ERR_NETWORK_CHANGED` on macOS 27 with Tailscale DNS enabled. The reported client is Tailscale 1.102.2, App Store/macsys. | This repository installs `tailscale-app`, so the reported installation variant differs. Confirm the installed client version and test Chrome plus tailnet DNS after upgrade. This is a conditional risk, not a confirmed break in this configuration. [Issue](https://github.com/tailscale/tailscale/issues/21330). |
| Tailscale | The September 10 release notes list version 1.102.4, including connectivity and custom coordination-server fixes. | These notes do not claim to fix issue 21330, which was filed later. An update alone cannot be represented as a verified fix. [Changelog](https://tailscale.com/changelog). |
| CleanShot X | Version 4.8.9 fixes Golden Gate capture, desktop-icon, and name-dialog problems. Version 4.8.11, September 18, adds compatibility improvements. Version 5.0.1 also released September 18. | Compare the installed version and license-supported release with these fixes. The notes do not establish that every 5.x behavior is identical to 4.8.11. [Changelog](https://cleanshot.com/changelog). |
| Superwhisper | Version 2.18.3, September 3, fixes a macOS 27 editor crash and recorder-window dragging, with additional macOS 27 fixes. | Confirm the installed app includes 2.18.3 or later. [Changelog](https://ai.superwhisper.com/changelog). |
| FlashSpace | The latest release page shows 4.18.79, September 7, with app-hiding, integration-timing, and shortcut fixes. The inspected release notes do not explicitly certify macOS 27. | Test workspace activation, app focus, multi-display behavior, and Accessibility permission. Lack of an explicit statement is not evidence that it fails. [Releases](https://github.com/wojciech-kulik/FlashSpace/releases). |
| LinearMouse | The inspected release page contains no explicit Golden Gate support statement. | Mouse movement and scrolling remain runtime checks. [Releases](https://github.com/linearmouse/linearmouse/releases). |
| Rectangle Pro | The vendor's versions page identifies historical macOS minimum-version branches but does not establish macOS 27 compatibility. | Window movement and shortcuts remain runtime checks. [Versions](https://rectangleapp.com/pro/versions). |

Display Pilot 2 is installed and pinned at 1.12.4.0. BenQ currently lists
1.12.8.0 and a macOS 13-or-newer requirement; that minimum is not an explicit
macOS 27 certification. [BenQ specifications](https://www.benq.com/en-us/monitor/software/display-pilot-2/spec.html).

Herdr and the remaining GUI applications were not individually
certified in this research. Their presence in a Homebrew cask list is not a
compatibility guarantee.

## Installed versions and update behavior

The local audit found CleanShot 4.8.10, Superwhisper 2.18.3, Tailscale 1.102.4,
FlashSpace 4.18.79, Rectangle Pro 3.82, LinearMouse 0.11.4, Display Pilot 2
1.12.4.0, OneDrive 26.163.0823, and Ghostty 1.3.1.

CleanShot 4.8.10 predates the September 18 compatibility fix. The pinned cask
is 5.0, which also predates the latest 5.0.1 release. The vendor separately
maintains 4.8.11. Verify the appropriate license-supported upgrade before
proceeding. Superwhisper already includes the explicit macOS 27 fixes.
Tailscale is newer than the reported 1.102.2, but its release notes do not
establish that the DNS report is fixed; its issue comments were empty when checked.

The pinned Rectangle Pro cask is 3.90 while the installed app is 3.82.
`home/darwin/default.nix` sets `HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1`.
The relevant casks except Display Pilot declare self-updating behavior, so
`onActivation.upgrade = true` does not establish that a rebuild will update
all installed GUI applications. Changing the flake lock alone is not a complete
app-update plan. Any package update should follow this repository's declarative
management rules.

The pinned Homebrew cask metadata for `codex-app`, version 26.623.141536, marks
the cask deprecated as of 2026-07-12 with reason `discontinued` and replacement
`chatgpt`. This is a statement about the pinned cask metadata, not independent
confirmation of the vendor's product plans. It is a preexisting potential
rebuild-warning issue, not a macOS 27 incompatibility, and does not authorize
replacing the user's application. The local scan found no maximum-macOS
constraint excluding 27 in the configured macOS casks.

## Before and after an upgrade

1. Check that the installed CleanShot and Superwhisper releases include the
   documented compatibility fixes. Make any package changes through the Nix
   configuration and its normal rebuild process.
2. Retain a current backup before the OS upgrade, as Apple recommends in its
   [upgrade instructions](https://support.apple.com/en-us/127455).
3. Preserve the distinction between the warning-free local evaluation and
   actual activation. A Nix evaluation on 26.6.2 cannot test macOS 27 behavior.
4. After upgrading, verify Nix daemon access and a small Nix build, then verify
   activation when Michael next runs the approved rebuild command. Check FlashSpace,
   Rectangle Pro, LinearMouse, screen recording, dictation, and external display
   behavior in the actual login session.
5. Test both public Chrome browsing and the configured `nixbook-tailnet` SSH
   alias with Tailscale connected. Do not apply the DNS workaround from an issue
   report unless the problem actually reproduces and the chosen fix is encoded
   declaratively.

Repository rules prohibit agents from running rebuild, switch, or apply
commands. This research did not run any of them.
