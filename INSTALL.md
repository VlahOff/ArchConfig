# Arch installer V6

Run as your normal user:

```sh
./install-archV6.sh
```

An interrupted run resumes automatically at its unfinished stage. Completed
stages are skipped. Within the Flatpak stage, the selected full/minimal profile
and successfully installed apps are saved too. A stage that fails partway through
is retried from its beginning; individual commands in that stage can run again.

For a failure from an older script, which did not save progress, choose where to
continue. For the AnyDesk timeout during Flatpak installation:

```sh
./install-archV6.sh --from flatpak
```

The stages, in order, are `system`, `packages`, `services`, `aur`, `flatpak`,
`appimages`, `configs`, `shell`, and `grub`. Choose a later stage only when the earlier
stages have already been completed on that machine.

The final GRUB stage updates an existing `/etc/default/grub` with:

```ini
GRUB_DEFAULT=saved
GRUB_SAVEDEFAULT=true
GRUB_TIMEOUT_STYLE=menu
GRUB_TIMEOUT=5
GRUB_DISABLE_BOOTNEXT=true
```

It backs up the defaults and existing `/boot/grub/grub.cfg`, then regenerates the
menu using `grub-mkconfig`. If generation fails, the previous files are restored
and the stage remains available to resume. Systems without an existing GRUB setup
are skipped. To apply just this stage after updating the installer:

```sh
./install-archV6.sh --from grub
```

Flathub and Flatpak apps are installed using `sudo` and Flatpak's default
system-wide installation, making the apps available to all users.
If you previously ran the per-user version,
run `./install-archV6.sh --from flatpak` to clear saved Flatpak progress and install
the selected profile system-wide. Existing per-user installations are left in place.

Each Flatpak is installed separately, with up to three attempts and a five-second
delay between attempts. After repeated failure, choose **r** to retry, **s** to
skip that app and continue, or **q** to stop and resume later. Skipped apps are
listed again at the end. Use `--from flatpak` to retry them; existing apps are
handled with Flatpak's `--or-update` option.

To deliberately start over, including choosing a new Flatpak profile:

```sh
./install-archV6.sh --restart
```

After a completed run, a normal invocation also starts a new run. Progress is
stored per user and checkout under
`${XDG_STATE_HOME:-$HOME/.local/state}/archconfig/install-arch-v6/`.
Moving the checkout creates a separate progress record. Concurrent runs of the
same checkout are rejected.

Run the isolated regression tests without installing software or changing services:

```sh
python3 -B -m unittest discover -s tests -v
```
