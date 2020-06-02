---
# Feel free to add content and custom Front Matter to this file.
# To modify the layout, see https://jekyllrb.com/docs/themes/#overriding-theme-defaults

layout: default
title: "ChooChoo: Steam-Powered Init"
---

# ChooChoo: Steam-Powered Init

## Submission

As with previous assignments, we will be using GitHub to distribute skeleton code and collect submissions.
Please refer to our [Git Workflow](https://cs4118.github.io/dev-guides/git-workflow) guide for more details.
Note that we will be using multiple tags for this assignment, for each deliverable part.

## Part 1: Inspection

Take a look at the current state of `traind` by inspecting the provided skeleton code. Note that if `fork`
were to fail somehow, we just continue looping it; also note how the parent is looped if/when the child
exits. This is all because our init process _cannot_ exit, no matter what. Keep this principle in mind going
forward: error-handling must be met by either looping or skipping. 

Make sure you understand the arguments being passed to `agetty(8)`—which virtual console will we be working
with?

Keeping all this in mind, let's take `traind` for a spin.

1. _Take a snapshot of your VM_. The following steps will be difficult to recover from otherwise.

2. Build, install by setting `/sbin/init` as a symbolic link to `traind`, and poweroff:
```
$ ls -l /sbin/init
lrwxrwxrwx 1 root root 20 May  8 17:33 /sbin/init -> /lib/systemd/systemd
$ make
$ sudo ln -sf $PWD/traind /sbin/init
$ ls -l /sbin/init
lrwxrwxrwx 1 root root 26 May  8 17:34 /sbin/init -> /home/kent/choochoo/traind
$ sudo poweroff
```
3. Start your VM: on booting up, it may appear that you're stuck on a black screen. Note that you can
   switch between virtual consoles by `Ctrl`+`Alt`+`Fn`, where `Fn` is the function key associated with
   `ttyN`.

   - Note: if this doesn't work, try `Host`+`Fn` instead, where `Host` is the host key for your VM.

4. Once logged in, attempt these basic tasks: create/edit a file, and use `sudo` to accomplish a privileged
   task. _Take note of the errors you get for later_.

5. Use `exit` to end your shell session. What happens?

Exit out of your VM and restore from the previous snapshot.

### Deliverables

- Answer the following in your `README.txt`:

   - By your findings on `agetty(8)` (and perhaps additional experimentation):

      - Describe the purpose of each argument passed.

      - Outline the chain of events by which your shell program is ultimately executed, including
        how it is selected (between `bash`, `dash`, `zsh`, etc.).

   - Describe what happened, and why, upon `exit`.

### Submission

To submit this part, push the `choochoop1handin` tag with the following:

```
$ git tag -a -m "Completed choochoo part1." choochoop1handin
$ git push origin master
$ git push origin choochoop1handin
```

## Part 2: Critical repairs

It should be clear that `traind` is a fixer-upper. First, let's get things usable—we should be able
to boot on `traind`, accomplish basic local tasks, and safely boot back into `systemd` afterward
(without needing to restore a snapshot).

From here on, as much or as little of `traind` may be implemented by shell scripts/commands as is
convenient. Technically, you could implement everything as a script, or everything as C code; you will
find the easiest route is somewhere in between. Any `*.sh` files you create in this directory will be
installed to `/etc/traind` by the Makefile, so if you want to execute one of your own scripts, do so
from that directory. Or you can embed scripts inline; the `-c` flag of your POSIX-compliant shell
interpreter (`/bin/sh`) is handy for this.

### Tasks

- Add checks at the beginning to make sure the user has root privileges (we'll need it) and that
  `traind` is indeed running as the init process; if not, exit with an error status.

- As of now, `traind` won't necessarily run forever—a signal could kill it. Set _all_ signals to
  be ignored.

   - You may find the `NSIG` macro useful in implementing this (for iterating over all signals); also
     see `signal(7)`.

   - Remember that you will have to reset all signals back to their defaults for any child process.

- Ensure that `traind` is its own session leader, and that any spawned child is as well—our init
  process should not be sharing a group with anyone else.

- Fix the problems found on Step 4 of Part 1.

   - You'll probably need to do some Googling, but you may find any of the following to be a helpful
     starting point: `mount(8)`, `mount(2)`, `hostname(1)`, `sethostname(2)`.

   - As a last resort, try the following sources; note that there is a _lot_ of extraneous
     information here, so make sure you have some sense of what you're looking for:

      - https://en.wikipedia.org/wiki/Linux_startup_process

      - https://www.debian.org/doc/manuals/debian-reference/ch03.en.html

- Address the issue encountered on Step 5: ensure that `agetty` is always respawned if it exits.

- Recall from lecture that it is the job of the init task to adopt any orphans; presently, `traind`
  doesn't take this into account. Ensure that orphan processes are always taken care of.

- Take a look at the provided `poweroff` and `reboot` scripts—you should implement `traind` so that
  these will work properly. Our shutdown sequence should kill all other processes by repeatedly sending
  `SIGTERM` at some regular  interval until it is unable to find any remaining processes to signal. If
  still going once 10 seconds has passed, send a `SIGKILL` and move on. You should also make sure to undo
  any setup done by `traind` on startup. See `reboot(2)` or `halt(1)` for initiating the actual shutdown.

   - Hint: you will need to un-ignore some signals for this.

   - Make sure you take any necessary steps to avoid incurring data loss.

### Tips

- Use `sudo make coupled` to build/install this time. 

   - Note that the file `/etc/nsswitch.conf` is modified; this is to disable the reliance on `systemd`
     (our current init program) for name-service information, as it slows down user authentication
     programs quite a bit when `systemd` isn't running. The change is undone by the `uncoupled` Makefile
     target.

   - After the install, `poweroff` and `reboot` will be ineffective until you're running `traind`. You
     must shutdown by other means, such as `shutdown(8)`.

- When you're running `traind` and are ready to return to `systemd`, use `sudo make decoupled`. _This
  will power off your VM_ (assuming you've implemented the shutdown sequence properly in `traind`).

   - Note: you could build the `uncoupled` target to uninstall without shutting down; if you do so, you
     will have to `sudo ./poweroff` on your own. Having reverted `/etc/nsswitch.conf`, it will be painfully
     slow to use `sudo` again until you're booted back on `systemd`, so this isn't recommended.

- When switching init systems in either direction, please shutdown the VM entirely before booting—don't
  reboot directly. If you do, you may get a scary error message and have to kill your VM manually (albeit
  this doesn't seem to have any lasting impact).

- At this point, it's recommended that you still take snapshots before switching init systems, and push
  your changes while running `systemd`; we don't have network services started on `traind` yet.

- Keep `agetty` on the same console as before for now—there is a pesky daemon running that is reading
  from the first (default) virtual console, so if you start on that one, it will unpredictably eat up
  your keyboard input and make for a frustrating user experience. We'll deal with this later.

### Deliverables

- Your updated `traind.c` (+ any scripts you've employed).

### Submission

To submit this part, push the `choochoop2handin` tag with the following:

```
$ git tag -a -m "Completed choochoo part2." choochoop2handin
$ git push origin master
$ git push origin choochoop2handin
```

## Part 3: Basic amenities

Now `traind` gets us somewhere—but the trip isn't especially pleasant. We'd like to not have to worry
about which console we're on, for starters. 

The aforementioned pesky daemon (interfering with `tty1`) is called `plymouthd`; to stop it, there is 
a boot script available to us in `/etc/init.d`. Going forward, we will be taking advantage of several
scripts from this directory. You can read more about these scripts
[here](https://wiki.debian.org/LSBInitScripts), but there's no need to get caught up in the details
of the standard—it's actually deprecated in Debian. We're just going to note the `Required-Start:`
and `Required-Stop:` rules at the top of each script, which outline dependency information. Read
about how these are interpreted; for our purposes, we can ignore any dependencies which aren't other
scripts available in `/etc/init.d`. Additionally, note that each script has available a `start` and
`stop` action, among others.

### Tasks

- For basic system setup, start the following boot services (as well as any dependencies):

   - The service which kills `plymouthd`.

   - The service which syncs up our system clock.

   - The service which ensures that `sudo` is set up properly.

- Make six virtual consoles available by spawning six instances of `agetty` on `tty1`-`tty6`; these
  should all still be respawned if/when they exit.

   - You should be able to switch between these and always see a login prompt or shell session.

- Update your shutdown routine for any additional cleanup.

### Requirements

- Any boot script you launch must be logging to the _current console_—that is, the console which
  is being viewed at the time the script is executed. This means you must set the standard stream
  file descriptors accordingly. Identify a special device to use in fulfilling this purpose (these
  are found in `/dev`).

   - Note that there is a distincion between the _current_ versus the _controlling_ terminal of a
     process—it may be helpful to look into this.

   - Note that it would not be sufficient to `open(2)` such a device file only once for the runtime
     of `traind`—the resulting file descriptor would only point to what was the current console _at
     the time of opening_. You will have to `open` this special device every time you wish to
     obtain the most up-to-date descriptor.

   - It's recommended that you approach your own logging this way as well, if any; however, this
     is not required.

- Neither `traind` nor any spawned child processes (except `agetty`) should take on a controlling
  terminal at any point—make sure you always `open(2)` the terminal device with any necessary
  flag(s) to keep it this way.

- You must wait on each boot script to finish completely.

- You may _not_ start any extraneous boot scripts—this is considered shotgunning and will incur a
  deduction.

### Deliverables

- Your updated `traind.c` (+ any scripts you've employed).

### Submission

To submit this part, push the `choochoop3handin` tag with the following:

```
$ git tag -a -m "Completed choochoo part3." choochoop3handin
$ git push origin master
$ git push origin choochoop3handin
```

## Part 4: First-class amenities

We've taken care of the basics, but those users who appreciate the finer things—such as network
connectivity—might expect more. Let's take care of them.

### Tasks

- Mount/enable any additional filesystems/swaps listed in `/etc/fstab` (note that a "swap" is
  some space on disk to use in case you ever run out of memory—definitely nice to have).

   - See `fstab(5)` for an explanation of this file; make sure you understand which filesystems
     _not_ to mount.

   - You may find any of the following helpful: `mount(8)`, `mount(2)`, `swapon(8)`, `swapon(2)`,
     `getmntent(3)`.

   - Note that by default, your `/etc/fstab` may not be configured to mount anything at boot;
     it's up to you to modify it for testing. Try finding a device you can set to be mounted.

- POSIX shared memory objects (as created by `mmap(2)` and `sem_open(3)`, for example) rely on
  a certain virtual filesystem for memory; confer with `shm_overview(7)` and ensure it is
  created/mounted.

- Start all boot services which relate to setting up networking and SSH, as well as any of their
  dependencies.

   - Note that Part 3's requirements still apply.

- Update your shutdown routine for any additional cleanup; also, unmount any filesystems that
  the user might have mounted since boot, as listed in `/proc/mounts`. This does _not_ include
  any filesystems of type `proc`, `sysfs`, `devtmpfs`, or `devpts`—these are kernel-exported
  virtual filesystems that would have been present on boot, so we should leave them how we
  found them.

   - You may find the following helpful: `umount(8)`, `umount(2)`, `swapoff(8)`, `swapoff(2)`,
     `getmntent(3)`.

   - Dig through `mount(8)` for more information on `/proc/mounts`.

### Tips

- Use `findmnt(8)` for a detailed overview of what you have mounted at any given point.

- Certain tasks here will be much easier depending on whether you choose to use shell
  command(s) or C code—do some reading before jumping in, and you'll save yourself a lot
  of time.

- Some of the network daemons like to dump information onto the console after-the-fact, which
  might end up on your login prompt if boot is too fast; you can just ignore this, or hit enter
  a few times to get past it.

### Deliverables

- Your updated `traind.c` (+ any scripts you've employed).

### Submission

To submit this part, push the `choochoop4handin` tag with the following:

```
$ git tag -a -m "Completed choochoo part4." choochoop4handin
$ git push origin master
$ git push origin choochoop4handin
```

## Part 5: Next stop — Graphics Central

We're just about there! Next stop — Graphics Central.

### Tasks

- Start the boot services which relate to setting up our GUI and display manager; as before, mind
  any dependencies.

   - Note that Part 3's requirements still apply.

- Update your shutdown routine for any additional cleanup.

- When our shutdown routine begins, it's likely we won't be in a text-based virtual console, in
  which case our scripts' logging won't be seen; the shutdown will feel too sudden. Fix this by
  setting one of our `agetty` virtual consoles to be activated just prior to this sequence.

   - You will find these helpful: `ioctl(2)`/`ioctl_console(2)` or `chvt(1)`.

   - If using `ioctl`, use `VT_WAITACTIVE` to block until the console is actually switched.

Take a look at `ps -e`; can you see why we start exactly six `agetty` terminals?

### Deliverables

- Your updated `traind.c` (+ any scripts you've employed).

- In your README.txt: explain why we only spawn `agetty` instances on `tty1`-`tty6`.

### Submission

To submit this part, push the `choochoop5handin` tag with the following:

```
$ git tag -a -m "Completed choochoo part5." choochoop5handin
$ git push origin master
$ git push origin choochoop5handin
```

## Part 6: Justifying the theme (optional)

To complete our steam-powered `traind` init system, let's set a proper boot animation.

First, obtain your Steam Locomotive:

```
sudo apt-get install sl
```

Then, on boot:

1. Start `sl` as a child process to execute concurrently, hooked up to the current console.

2. Redirect all boot scripts to `/dev/null`.

   - This step is optional; it helps, but ultimately those pesky network daemons are going to dump
     text onto the active console regardless, so it will never be pristine.

3. Before starting the display manager service, wait for `sl` to terminate (so that we're not
   switched to the GUI mid-train).

   - You could actually just kill `sl` when the boot scripts are done (pass the `-e` flag on start
     and send `SIGINT`), but this would go against the spirit of `sl`.

4. ChooChoo!

![](sl-boot.gif)

### Submission (optional)

To submit this part, push the `choochoop6handin` tag with the following:

```
$ git tag -a -m "Completed choochoo part6." choochoop6handin
$ git push origin master
$ git push origin choochoop6handin
```

-----------------------------------------------------------------------------------------------------------

### _Acknowledgment_

The ChooChoo assignment and reference implementation were designed and implemented by the following
TAs of COMS W4118 Operating Systems I, Spring 2020, Columbia University:

- John Hui, probably

-----------------------------------------------------------------------------------------------------------

_Last updated: 2020-06-01_
