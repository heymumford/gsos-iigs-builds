# Apple IIGS "Unlock" Landscape

**As of:** 2026-05-05

This document surveys what the Apple IIGS hardware can do that the factory GS/OS leaves on the table, where GS/OS exposes legitimate extension points for net-new code, what the community has already published, and which slice candidates the project should target next. It is the source-of-truth for future "unlock" extension slices and is bound by D-009 (no Apple binary modification), D-010 (Ghidra-driven analysis), and D-011 (extensions are net-new code only).

Voice rule per `~/.claude/context/writing.md`: declarative for cited facts, conditional for inferences.

---

## 1. Hardware surface area

### 1.1 65C816 CPU — the accelerator detection problem

The factory IIGS clocks the WDC 65C816 at 2.8 MHz with a software-selectable 1 MHz "slow mode" for legacy slot-card timing. The control panel exposes a binary fast/normal toggle and the GS/OS `SET_SYS_SPEED` hook.

What the factory leaves on the table: the platform shipped with no first-class API for third-party accelerator boards. Three commercial accelerators became dominant:

- **Applied Engineering TransWarp GS** — onboard 65C816 with cache, originally 7 MHz, later boards reach 12-14 MHz. Detection is via vendor-specific I/O at slot firmware addresses; ReActiveMicro's wiki documents the current production-board detection sequence and per-slot conflict matrix.
- **Zip Technology Zip GS / ZipChipGS** — cache-based design. Csa2 FAQ documents Zip-specific control register quirks and the GS/OS `SET_SYS_SPEED` interaction that made early Zip boards flicker until Apple fixed the cursor handler in System 6.0.1 (`ZipFix` was the community workaround).
- **Phaser FastChip / AppleSqueezer GS** — modern revivals. AppleSqueezer GS hosts a 14 MHz 65C816 plus 5 MB onboard, cache-driven, single-board accelerator + memory expansion.

Because each board exposes a different detection register and a different speed-control interface, applications that want to set themselves up correctly (audio sample-rate scaling, animation frame pacing) must hand-roll detection per board. There is no "what accelerator am I on?" GS/OS call.

Citations:
- Apple IIGS Hardware Reference, Ch. 1, "The Core of the Apple IIGS" (Internet Archive: `archive.org/details/Apple_IIgs_Hardware_Reference`).
- ReActiveMicro Wiki, TransWarp GS page (`wiki.reactivemicro.com/TransWarp_GS`).
- Csa2 Apple II FAQs, `ACCELERATORS` section, archived at `gswv.apple2.org.za/a2zine/faqs/Csa2ACCEL.html`.
- Applefritter, "AppleSqueezer GS" thread (`applefritter.com/content/applesqueezer-gs-new-iigs-accelerator-memory-expansion`).
- Wikipedia "Apple II accelerators" (`en.wikipedia.org/wiki/Apple_II_accelerators`).

### 1.2 Mega II custom chip — built-in legacy peripherals never wired up

The Mega II is the "Apple IIe on a chip" that gives the GS its 8-bit compatibility. The Hardware Reference (Ch. 4) covers the documented IOU/MMU behavior and Apple-supplied register set.

What the factory leaves on the table: Mega II contains a built-in keyboard controller and a built-in mouse controller, neither of which Apple wired up on the IIGS motherboard — the IIGS routes keyboard and mouse through the ADB GLU and Slotmaker chips instead. The element14 "Mega IIe" project demonstrates the Mega II's keyboard controller working as a standalone Apple II clone, confirming the unused capability is real silicon rather than documentation noise. Mega II also contains the `IOU` interrupt latch and the slot-1/slot-2 dual-VBL routing that GS/OS abstracts away — direct programming of the VBL latch is documented in the Hardware Reference but the cleaner GS/OS side has no Toolbox call to register a scanline callback.

Citations:
- Apple IIGS Hardware Reference, Ch. 4 "The Video Displays" and Ch. 2 "The Core of the Apple IIGS."
- Wikipedia "Mega II" (`en.wikipedia.org/wiki/Mega_II`).
- element14 Community, "Mega IIe: First Fully Functional Computer built around the Apple Mega-II Chip" (Episode-630).
- Applefritter "IIGS Custom Chips" reference (`applefritter.com/content/iigs-custom-chips`).

### 1.3 IWM (Integrated Woz Machine) and SmartPort — protocol headroom

The IWM dispatches three families of disk media: 5.25" floppies (Disk II protocol), 3.5" floppies (`.Sony` driver, GCR-encoded), and SmartPort (the byte-level protocol used for hard-disk-class devices). The IWM is the same custom chip used in the original Macintosh; Apple IIc Plus and IIGS extend it through SmartPort dispatch.

What the factory leaves on the table: SmartPort is a protocol, not a media spec. The community has used the SmartPort dispatch surface to implement IDE-CompactFlash bridges (`CFFA3000`), SD-card bridges (`MicroDrive/Turbo`, `Booti`), USB-floppy emulation (`FloppyEmu`), and over-network virtual disks (`WDRIVE`). The "SmartPort Secrets" reference from Mike Guidero documents the firmware dispatch convention that an emulator-side BlockDev driver could target.

The constraint: SmartPort speed is bounded by the IWM's serial clock when the device-side block-cache is empty. CFFA3000 is PIO; MicroDrive/Turbo uses DMA and is faster (per the r/apple2 thread). A modern emulator-side BlockDev driver targeting GSplus or MAME would inherit the same protocol but not the bus-clock cap.

Citations:
- Apple IIGS Firmware Reference (referenced from Apple Tech Note `tn.smpt.2.html`, mirrored at `1000bit.it`).
- Mike Guidero, "Apple IIc Plus: SmartPort Secrets" (`apple2.guidero.us/doku.php/articles/iicplus_smartport_secrets`).
- ReActiveMicro Wiki, `MicroDrive/Turbo` page.
- Higher Intellect Vintage Wiki, "MicroDrive IDE Card."
- r/apple2 thread on CFFA3000 vs. MicroDrive/Turbo vs. FloppyEmu speed tradeoffs.

### 1.4 Ensoniq 5503 DOC — 32 oscillators, 8 typically used

The DOC is a 32-oscillator wavetable synth shared with the Ensoniq Mirage and SQ-80 keyboards. It produces 8-bit waveforms with a center line at $80 ($00 = stop), has per-oscillator frequency-low/frequency-high/volume/address/control registers, and a configurable wavetable size. The Brutal Deluxe-mirrored ENSONIQ DOC ERS (Engineering Requirements Spec, June 1986, Apple Confidential) is the canonical low-level reference.

What the factory leaves on the table: most GS/OS applications use 8-16 oscillators because `Sound Manager` and the Note Synthesizer Toolbox fix per-instrument allocation conservatively to avoid voice starvation. With pair-mode (each "voice" is two oscillators in primary/swap, freeing the active one to retrigger without click), 16 is the typical practical voice count — but the silicon supports 32 single-shot or 16 paired voices simultaneously. Modular synthesis, granular synthesis, and sampled-instrument tricks (the latter shipped in Soundsmith / Tool219 and NinjaTracker / Tool221) demonstrate the headroom. The 4soniq card extends Soundsmith to 8 stereo channels by adding a second DOC, but the original DOC alone has unused polyphony when only one application owns the audio device.

Citations:
- Ensoniq 5503 DOC ERS (Apple Confidential, June 1986), mirrored at `brutaldeluxe.fr/documentation/cortland/v4_13_EnsoniqDOC.pdf`.
- "SOUND GS - Part 6 Sound and Music," archived at `gswv.apple2.org.za/USA2WUG/A2.LOST.N.FOUND.CLASSICS/SOUND.GS.5503.ensoniq.txt`.
- Brutal Deluxe NinjaTracker Tool221 page (`brutaldeluxe.fr/products/apple2gs/tool221/`).
- Brutal Deluxe Soundsmith / Tool219 page (`brutaldeluxe.fr/products/apple2gs/soundsmith/`).
- a2fpga FPGA reimplementation of the DOC5503 in SystemVerilog (`github.com/a2fpga/a2fpga_core/blob/main/hdl/sound/doc5503.sv`).

### 1.5 VGC — documented modes vs. demoscene tricks

The VGC supports two officially documented Super Hi-Res (SHR) modes: 320x200 with 16 colors per scanline (16 palettes of 16 colors each, declared in scan control byte) and 640x200 with 4 colors per scanline. Apple IIGS Hardware Reference Ch. 4 documents the scan-line interrupt, the VGC interrupt register at `$C023`, and the interrupt-clear register at `$C032`. These are the supported inputs.

What the factory leaves on the table:

- **3,200-color mode** — by swapping all 16 palettes between scanlines (200 lines × 16 palette entries), the screen can show up to 3,200 distinct colors simultaneously. The CPU must run synchronized to the scanline interrupt with the VGC's scan-line trigger; the VGC itself does not do this. Dream Grafix and other paint programs ship support but render slowly because every paint operation costs a full palette-swap CPU pass.
- **Mid-frame palette swap** — Brutal Deluxe / FTA / Ninjaforce demos (NinjaTracker Tool221, MEGADEMO, KABOOM!, Kernkompetenz) demonstrate dynamic palette modulation per visible frame for animation-without-redraw effects. The technique is documented across the demoscene corpus but has no first-class GS/OS API.
- **Sprite-on-blank** — using the VBL period to redraw small regions, demos achieve sprite-like motion the VGC does not natively support.

The architectural gap: the VGC scanline interrupt is exposed at the firmware level only. A registered-callback API at the GS/OS layer would let apps subscribe to scanlines without each one rebuilding the IRQ trampoline.

Citations:
- Apple IIGS Hardware Reference Ch. 4 "The Video Displays" (figures 4-2 through 4-4).
- Wikipedia "Apple IIGS" (3,200-color section).
- Demozoo Apple IIGS platform page (`demozoo.org/platforms/57/`).
- Retrocomputing StackExchange, "How were sprites handled on the IIgs?" (Q28219).
- Apple2History, "What Is A Demoscene?" (`apple2history.org/2012/07/19/what-is-a-demoscene/`).
- Ninjaforce demoscene retrospective (`ninjaforce.com/html/special_demoscene.html`).
- Brutal Deluxe archive (`brutaldeluxe.fr/archive.html`).
- "What is the Apple IIGS?" Dream Grafix entry on 3,200-color authoring tradeoffs.

---

## 2. GS/OS extension points

GS/OS exposes seven extension surfaces where net-new code attaches without modifying Apple binaries. The canonical reference is GS/OS Reference Volume 1 (Apple, 1990 Addison-Wesley); Chapter 8 covers FSTs and Chapter 9-10 cover device drivers. The disassembly project at `6502disassembly.com/a2-gsos/` provides annotated listings of the shipping GS/OS 6.0.1 FSTs as a reading aid (annotations only; no Apple bytes redistributed).

| Path on a GS/OS boot disk | Purpose | Reference |
|---|---|---|
| `*/SYSTEM/DRIVERS/` | Block / character device drivers (`.Sony`, `.Disk3.5`, SmartPort dispatchers, network link drivers). Drivers register with GS/OS via the `Driver_Mover` mechanism documented in GS/OS Reference Vol. 1, Ch. 9. | GS/OS Reference Vol. 1, Ch. 9 "Device Drivers." |
| `*/SYSTEM/FSTs/` | File System Translators. Named FSTs ship for ProDOS, HFS, Apple II DOS 3.3, MFS, AppleShare/AFP. Each FST implements a fixed dispatch table whose entries the FST_BOOT call wires in. | GS/OS Reference Vol. 1, Ch. 8 "File System Translators." |
| `*/SYSTEM/CDEVS/` | Control Panel devices. CDevs are GS/OS-loaded resources that render in the New Desk Accessory Control Panel. | Apple IIGS Toolbox Reference Vol. 2, Chapter on Control Panels (`mirrors.apple2.org.za/.../Apple%20IIGS%20Toolbox%20Reference%20Volume%202.pdf`). |
| `*/SYSTEM/SYSTEM.SETUP/` | Init files auto-loaded at GS/OS boot, before the Finder. Used for AppleTalk init, scheduler/daemon launches, hardware-detection drivers. | "What is the Apple IIGS? > System Extensions" archive (`whatisthe2gs.apple2.org.za/system-extensions-or-create-your-killer-gs-os-environment/`). |
| `*/SYSTEM/EXTENSIONS/` | System extensions loaded after `SYSTEM.SETUP`. Patch toolbox vectors, install background tasks, register CDA/NDA additions. | Apple IIGS Toolbox Reference Vol. 2, "System Extensions" chapter. |
| `*/ICONS/` and `*/SYSTEM/TOOLS/` | Icon files + supplementary toolset resources (Tool number assignments). Tool220+ are the user-extension range; Tool219 (Soundsmith), Tool221 (NinjaTracker) are real precedents. | Apple IIGS Toolbox Reference Vol. 2, Tool numbering appendix. |
| Toolbox-call dispatcher (`$E10000` via TLINK soft-vector) | Toolbox patches via the universal Toolbox-call dispatcher, applied at Init time by an extension. | Apple IIGS Toolbox Reference Vol. 1 (general toolkit dispatching); GS/OS Reference Vol. 1 on TLINK. |

Three notes on these surfaces:

1. **Tool220+ is open territory.** Apple reserved tool numbers 1-219 for first-party use; the demoscene precedent (Tool219 Soundsmith, Tool221 NinjaTracker) demonstrates that registering net-new toolsets is well-trodden. A new Toolset that exposes accelerator detection or DOC polyphony management lives here cleanly.
2. **`SYSTEM.SETUP/` runs before any user code.** This is the only surface where pre-boot hardware detection (probing accelerator I/O, sniffing for additional DOCs / 4soniq cards) can land its results before the first application launches.
3. **CDevs are the user-visible surface.** Anything that needs Control Panel UI (oscillator-allocation slider, accelerator speed display, scanline-trick toggle) belongs here; `SYSTEM.SETUP` does the headless work and the CDev exposes the configuration.

Citations:
- GS/OS Reference Vol. 1 (Internet Archive: `archive.org/stream/gs_os_reference_vol_1/gs_os_reference_vol_1_djvu.txt`).
- Apple IIGS Toolbox Reference Vol. 2 (Internet Archive: `archive.org/details/apple_iigs_toolbox_reference_volume_3` for Vol. 3 and Vol. 2 cross-index; PDF mirror at `mirrors.apple2.org.za`).
- 6502disassembly GS/OS FST disassembly (`6502disassembly.com/a2-gsos/`).
- "What is the Apple IIGS? > System Extensions" community archive.

---

## 3. Community precedents

What community-shipped extensions exist, what extension point each uses, and what hardware each unlocks.

| Project | Extension point | Hardware unlocked | Citation |
|---|---|---|---|
| Marinetti (TCP/IP stack) | `SYSTEM.SETUP` (Marinetti TCP/IP CDev) + Link Layer drivers in `DRIVERS/` (Uthernet II driver by Ewen Wannop; Apple-Talk/MacIP fallback) | Network interface cards (Uthernet II, AppleTalk-bridged hosts) | `apple2.org/marinetti/`; `a2retrosystems.com/Marinetti.htm`; SourceForge mirror `sourceforge.net/projects/marinetti/`. |
| GNO/ME (Multitasking Environment) | Patches GS/OS via kernel-level toolcalls; layered on top of GS/OS, not a strict extension. Does not modify Apple binaries — runs as alternate shell + kernel. | 65C816 multitasking, signals, pipes, fork/exec on top of GS/OS | `gno.org/gno/`; `github.com/GnoConsortium/gno-docs`; Bazyar GNO Kernel Reference (`gno.org/gno/refs/kernel/kern.a4.pdf`). |
| The Manager (Brainstorm Software / Seven Hills) | System Extension + Toolbox patches. Cooperative multifinder. | 65C816 multi-application context-switching; was sold as a Mac MultiFinder analog | Wikipedia "Apple IIGS"; `whatisthe2gs.apple2.org.za/the-manager.html`. |
| CFFA / CFFA3000 (R&D Automation) | SmartPort `DRIVERS/` (a2disk-style block driver) and slot-firmware ROM | CompactFlash card → ProDOS / HFS volume; PIO-bound. | r/apple2 CFFA3000 thread; Applefritter "FloppyEmu vs. CFFA3000/Booti." |
| MicroDrive / Turbo (ReActiveMicro) | SmartPort `DRIVERS/` block driver + firmware ROM with DMA support | CompactFlash card → ProDOS / HFS / GS/OS, DMA-fast | `wiki.reactivemicro.com/MicroDrive/Turbo`; Higher Intellect "MicroDrive IDE Card." |
| FloppyEmu (BMOW) | SmartPort dispatch (looks like 3.5"/SmartPort device) | SD card → emulated 5.25"/3.5"/SmartPort volume | r/apple2 CFFA3000 thread (comparison). |
| Spectrum (Ewen Wannop) | GS/OS desktop application + `DRIVERS/` for serial-line VT100 / ANSI / ProTERM emulation | Modem-era serial connectivity; SHR-mode color text rendering | `wannop.info/speccie/downloads/Spectrum.inf`; A2Central article; Applefritter "ProTERM, ANSITERM, or Spectrum?" |
| NinjaTracker / Tool221 (Brutal Deluxe + Ninjaforce) | Custom Toolset registered as Tool number 221 | DOC oscillator-pool playback of Soundsmith-style MOD files; first-class API for any application to call | `brutaldeluxe.fr/products/apple2gs/tool221/`; `ninjaforce.com/html/products_ninjatracker.html`. |
| Soundsmith / Tool219 (FTA / Huibert Aalbers) | Toolset 219; v2 supports 4soniq second-DOC card | DOC sample-instrument playback as registered Toolbox API | `brutaldeluxe.fr/products/apple2gs/soundsmith/`. |
| Cadius / OMF Manipulator (Brutal Deluxe build tools) | POSIX-side build tooling, not a GS/OS extension. Listed because they unlock the *toolchain* surface for building Tool220+ extensions. | OMF object file manipulation, ProDOS volume scripting | `brutaldeluxe.fr/products/apple2gs/`. |

The most surprising precedent for this project's purposes is **NinjaTracker as Tool221**: Brutal Deluxe and Ninjaforce shipped DOC polyphony as a *registered Toolbox tool number*, not as a standalone application. That means the architectural pattern for a "DOC polyphony manager" slice candidate (U-3 below) is not novel — it has been done, with a citation precedent, and the slot is reserved by community convention starting at tool 220.

---

## 4. Slice candidates for next waves

Each candidate names: hardware unlocked, extension point used, public APIs cited, closest community precedent, and one-line "smallest testable green" criterion.

### Slice candidate U-1 — Accelerator detection init file

- **Hardware unlocked**: TransWarp GS, Zip GS / ZipChipGS, AppleSqueezer GS, Phaser FastChip (4 known production accelerators).
- **Extension point**: `SYSTEM/SYSTEM.SETUP/` init file; exposes results as a registered Toolset (Tool 222 candidate).
- **Public APIs cited**: GS/OS `SET_SYS_SPEED` (Csa2 ACCELERATORS FAQ); board-specific I/O probes documented per ReActiveMicro Wiki (TransWarp), Csa2 (Zip), Applefritter (AppleSqueezer).
- **Closest community precedent**: `ZipFix` (community workaround for the Zip cursor-flicker bug). Spectrum's serial driver is also relevant — Wannop's pattern for shipping a `DRIVERS/` artifact is the same shape.
- **Smallest testable green**: ORCA/C source compiles with Golden Gate; init binary is type $B7 (System Extension); on a known-clean GS/OS image with no accelerator, the call returns "stock 2.8 MHz" without false positive. (Live-on-hardware verification deferred to a hardware-in-loop harness.)

### Slice candidate U-2 — VGC scanline-callback toolset

- **Hardware unlocked**: VGC scan-line interrupt (`$C023` / `$C032`); enables 3,200-color and mid-frame palette-swap effects via a clean callback API instead of per-app IRQ trampolines.
- **Extension point**: Tool 223 candidate (Toolset registered at boot via `SYSTEM.SETUP`). CDev for enabling/disabling scanline-trick mode.
- **Public APIs cited**: Apple IIGS Hardware Reference Ch. 4, figures 4-2 (Scan-line interrupt), 4-3 (VGC interrupt register), 4-4 (VGC interrupt-clear register).
- **Closest community precedent**: NinjaTracker Tool221 architectural pattern (Toolset that owns a hardware resource and multiplexes callers); Dream Grafix's 3,200-color authoring (proves the technique).
- **Smallest testable green**: Headless GSplus run shows the toolset registers, `SCANLINE_REGISTER` returns success, dispatched callback fires once per VBL on a 320x200 SHR canvas. JSON event log validates with `jq empty`.

### Slice candidate U-3 — DOC polyphony manager toolset

- **Hardware unlocked**: 32 DOC oscillators (currently capped at 8-16 by conservative `Sound Manager` allocation); supports clean voice multiplexing across multiple registered audio clients.
- **Extension point**: Tool 224 candidate (Toolset). Lives alongside Tool219 / Tool221 in the established demoscene-toolset range.
- **Public APIs cited**: Ensoniq 5503 DOC ERS (Brutal Deluxe mirror); Apple IIGS Toolbox Reference Vol. 2 Sound Manager / Note Synthesizer chapters.
- **Closest community precedent**: Soundsmith Tool219 (sample playback) and NinjaTracker Tool221 (MOD playback) — both shipped as registered Toolsets that own DOC voice ranges. U-3 is the meta-allocator they would coexist with.
- **Smallest testable green**: ORCA/C source compiles with Golden Gate; given two simultaneous registered clients each requesting 8 voices, the toolset returns disjoint oscillator ranges; on a third client requesting 17 voices, returns OOM cleanly without corrupting the first two clients' allocations.

### Slice candidate U-4 — Modern SmartPort driver for emulator-side BlockDev

- **Hardware unlocked**: SmartPort dispatch surface, exposing a host-side block device (POSIX file, block file, or local disk image directory) as a GS/OS volume to a running emulator (GSplus / KEGS / MAME).
- **Extension point**: `SYSTEM/DRIVERS/` block driver. Driver-side runs in the GS/OS image; host-side runs as an emulator backend.
- **Public APIs cited**: Apple IIGS Firmware Reference SmartPort dispatch; Mike Guidero "SmartPort Secrets"; CFFA3000 / MicroDrive/Turbo as functional reference designs.
- **Closest community precedent**: CFFA3000 (PIO-only) and MicroDrive/Turbo (DMA-capable) for the block-driver shape. FloppyEmu for the host-as-virtual-storage pattern.
- **Smallest testable green**: Phase 5 emulator-boot harness picks up a host-mounted ProDOS/HFS volume as `/EMUDISK/`; `ls /EMUDISK/` from a GS/OS shell shows the host directory contents; round-trip read/write of a 64 KB file matches host-side checksum.

---

## Citation gaps (TODO follow-up)

Inline gaps surfaced during this slice that future slices should close:

- **CDev binary format spec** — referenced in Apple IIGS Toolbox Reference Vol. 2 but the Internet Archive currently only exposes Vol. 3 by direct download; Vol. 2 is the cited PDF mirror at `mirrors.apple2.org.za` but a clean linkable canonical URL would strengthen U-2 and U-3 citations.
- **Tool number registry** — community convention reserves 220+ for non-Apple toolsets; `Tool219` (Soundsmith) and `Tool221` (NinjaTracker) are the published precedents. A canonical registry of allocated/unallocated tool numbers would let U-1 through U-3 declare unique numbers without collision risk. Brutal Deluxe and Ninjaforce are the de-facto coordinators; no published registry was found in this slice.
- **Phaser FastChip detection sequence** — mentioned in the brief but no canonical detection-register reference was found in published community sources; ReActiveMicro and Csa2 cover TransWarp and Zip cleanly but Phaser is thinner. U-1 should defer Phaser to a follow-up slice or treat it as a "reports unknown accelerator if present" branch.
- **Mega II VBL-direct-programming examples** — Hardware Reference documents the registers but a working example of `SYSTEM.SETUP`-installed scanline trampolining without going through Toolbox Sound Manager would clarify U-2's API surface. Brutal Deluxe demoscene archives likely contain this in source form; verification deferred.

These gaps are flagged for the next research slice; none block the slice candidates above from starting.
