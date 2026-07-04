#set document(
  title: "Comparative Analysis of Sandboxing and Mitigation Philosophies in Mobile User-Agent Architectures",
  author: "Independent Security Research",
)
#set page(
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2.5cm),
  numbering: "1",
  number-align: center,
)
#set text(font: "Times New Roman", size: 11pt)
#set par(justify: true)
#show math.equation: set text(size: 9.5pt)
#set heading(numbering: "1.1")

#align(center, text(size: 16pt, weight: "bold")[
  Comparative Analysis of Sandboxing and Mitigation\
  Philosophies in Mobile User-Agent Architectures
])
#v(6mm)
#align(center, text(size: 12pt, style: "italic")[
  A Rebuttal of Outdated Claims Against Gecko-Based Browsers on Android
])
#v(6mm)
#align(center, text(size: 11pt)[Independent Security Research])
#align(center, text(size: 11pt)[July 2026])
#v(2cm)

#show heading.where(level: 1): it => {
  pagebreak()
  heading(level: 1, numbering: it.numbering, it.body)
}
#line()

== Abstract
<abstract>
Hardened mobile deployment frameworks (most notably GrapheneOS) advise
against Gecko-based browsers like Firefox, claiming a systemic security
deficit compared to Chromium-based alternatives such as Vanadium. These
advisories show significant documentation latency. They cite
architectural deficiencies that have been partially or fully resolved in
current stable releases, conflate distinct mitigation layers
(pre-compromise versus post-compromise), and fail to account for
threat-model dependencies that alter the security calculus. This paper
evaluates these claims through a multi-layered threat-modeling lens
grounded in publicly available primary sources. It examines the
architectural evolution of GeckoView on Android, including the January
2026 shipping and subsequent rollback of Project Fission (Site
Isolation) in Firefox 147 (now at Firefox 152, July 2026), which remains
disabled on release and beta channels due to unresolved crash bugs
(Section 2.3). It covers structural pre-compromise defenses provided by
Firefox’s industry-leading Rust adoption, WebExtension isolation
architecture, and declarative content-blocking engine. It looks at the
intersection of privacy controls with exploit-chain disruption,
including Total Cookie Protection and Enhanced Tracking Protection. And
it considers the systemic security risk of a Chromium monoculture. The
analysis finds that categorical dismissal of either engine family is
unsupported by current evidence, and that browser selection is not a
binary metric of "secure versus insecure" but an alignment with a
specific threat model.

#line()

== 1. Introduction and Historical Context
<introduction-and-historical-context>
Criticism of Mozilla’s Gecko engine on mobile platforms has historically
centered on its single-process architecture. Before the completion of
multi-process re-architecting, Gecko-based browsers on Android lacked
robust site-level process boundaries, making them structurally
vulnerable to microarchitectural side-channel attacks such as Spectre
and Meltdown \[6\]. This deficiency was well-documented by Mozilla’s own
engineering team during the design phase of their multi-process
architecture \[4\].

Security guidance in the mobile ecosystem suffers from persistent
documentation latency. The most influential critique of GeckoView on
Android is GrapheneOS’s published advisory on web browsing \[1\]. It has
remained substantively unchanged while the target architecture has
evolved significantly. Criticisms rooted in architectural deficiencies
that have since been addressed continue to circulate as authoritative
guidance without reference to current implementation status.

This paper has two purposes. First, it provides an evidence-based,
up-to-date assessment of the security properties of both Chromium-based
and Gecko-based browser architectures on Android, distinguishing between
verified architectural properties, documented limitations, and areas
where public evidence is incomplete. Second, it offers a claim-by-claim
critical examination of GrapheneOS’s published position, identifying
where its assertions remain valid, where they have been superseded by
developments, and where they reflect divergent threat-model priorities
rather than objective security deficits.

#strong[Methodology.] All claims herein are accompanied by citations to
primary or secondary sources accessible as of July 2026. Where evidence
is absent or contradictory, this is explicitly noted. The authors have
no affiliation with Mozilla, GrapheneOS, the Chromium project, or any
commercial browser vendor.

#strong[Scope and limitations of this analysis.] This paper is a
threat-modeling analysis, not an empirical vulnerability comparison. It
evaluates architectural security properties, mitigation philosophies,
and the alignment of each browser engine with different threat-model
priorities. It does not attempt to measure or rank the absolute number
of vulnerabilities per browser, and it does not provide a quantitative
CVE comparison between Chromium and Firefox. Where vulnerability
statistics from published sources (such as Chromium’s memory safety data
\[14\]) are cited, they are used to illustrate architectural arguments,
not as comparative metrics. Readers seeking a direct CVE-by-CVE
comparison should consult the respective vendor security advisory pages
\[17\] and Chromium release notes.

#line()

== 2. Architectural Analysis of Process Isolation
<architectural-analysis-of-process-isolation>
=== 2.1 Kernel-Level Containment via `android:isolatedProcess`
<kernel-level-containment-via-androidisolatedprocess>
The Android platform exposes a mechanism for declaring sandboxed service
processes through the `android:isolatedProcess="true"` manifest
attribute. When set, the Android kernel assigns the child process a
heavily restricted, ephemeral User ID (UID). This UID is isolated from
the parent application’s permissions, file system access, and data
streams outside explicit Inter-Process Communication (IPC) channels
\[9\].

Chromium (and by extension Vanadium, GrapheneOS’s hardened fork) uses
this mechanism as the foundation of its renderer sandbox. Each renderer
process runs under an isolated UID with access restricted to its
assigned memory region and a narrow, explicitly defined IPC interface to
the parent browser process. GrapheneOS explicitly identifies this as the
strongest available sandbox implementation on Android \[1\], \[2\].

This mechanism provides a #strong[post-compromise containment]
guarantee. Even if an attacker achieves arbitrary code execution within
a renderer process, the `isolatedProcess` sandbox severely restricts
what system resources the compromised process can access. The attacker
must then find a separate sandbox-escape vulnerability (typically
targeting the browser’s IPC layer or a kernel vulnerability) to achieve
broader system access.

=== 2.2 GeckoView’s Mobile Sandboxing: The Current State
<geckoviews-mobile-sandboxing-the-current-state>
GeckoView does not implement the `isolatedProcess` mechanism for its
child processes on Android. This is a substantiated architectural
limitation that GrapheneOS correctly identifies \[1\]. The
`isolatedProcess` flag is a declarative Android manifest property – as
GrapheneOS describes it, "a very easy to use boolean property for app
service processes" \[1\]. Its absence in GeckoView represents a
deliberate engineering choice or resource-allocation decision by
Mozilla.

The characterization that "Firefox does not have internal sandboxing on
Android" conflates the absence of one specific sandboxing mechanism with
the complete absence of sandboxing. Three developments have altered this
assessment:

+ #strong[Multi-process architecture.] GeckoView on Android has operated
  a multi-process architecture with a privileged parent process and
  separate content processes since the completion of its multi-process
  re-engineering. This provides process-level isolation between content
  and the browser chrome, even if the kernel-level protections differ
  from Chromium’s.

+ #strong[Project Fission (Site Isolation) – shipped, then rolled back.]
  Mozilla shipped Site Isolation for Android in Firefox 147.0 (January
  2026), with release notes stating: "Added protection against
  side-channel attacks such as Spectre using the same Site Isolation
  safeguards already in use by desktop Firefox" \[12\]. However, Firefox
  147.0.2 (February 2026) disabled Fission on release and beta channels
  due to content process crashes causing random back-navigation (Bug
  2011319). The isolation strategy default was reverted to
  `ISOLATE_NOTHING` for all channels except nightly and developer
  \[27\]. As of Firefox 152 (July 2026), Fission remains disabled on
  release and beta channels. The root cause – content process crashes
  when isolating sites with Fission (Bug 2012435) – remains open with
  the fix still in progress \[29\]. On nightly and developer builds,
  Fission operates at `ISOLATE_HIGH_VALUE`, which isolates only "high
  value" sites (e.g., login pages) rather than providing full strict
  origin isolation. This is fundamentally different from Chromium’s site
  isolation model and means the cross-origin exfiltration protection
  described in the paper is currently unavailable on release Firefox for
  Android.

+ #strong[Memory safety via Rust (Section 3).] An increasing portion of
  GeckoView’s rendering pipeline is written in Rust, a memory-safe
  language that makes entire classes of vulnerabilities (use-after-free,
  buffer overflows) structurally impossible in safe code paths. This is
  a #strong[pre-compromise] defense that reduces the probability of
  successful initial compromise. It is distinct from and complementary
  to post-compromise containment.

=== 2.3 Project Fission on Android: Architecture and Caveats
<project-fission-on-android-architecture-and-caveats>
Mozilla announced Fission’s stable release for desktop Firefox in
version 95 (December 2021) \[3\], \[5\]. The desktop implementation
assigns each site origin to a dedicated operating system process, with
IPC enforcement ensuring that cross-origin data access requires
explicit, validated channels.

#strong[Fission shipped on Android in Firefox 147.0 (January 2026), but
was rolled back in 147.0.2 (February 2026) and remains disabled on
release and beta channels as of Firefox 152 (July 2026).] The isolation
strategy default is `ISOLATE_NOTHING` (0) for release and beta; only
nightly and developer channels have `ISOLATE_HIGH_VALUE` (2) \[27\]. The
original release notes cited Spectre-class side-channel protection
\[12\], but this protection is currently not active on the default
release configuration.

#strong[Rollback timeline.]

+ #strong[Bug 2003658] (December 2025/January 2026): Fission + SHIP
  turned on by default for Firefox 147 \[30\]. The initial
  implementation shipped with `ISOLATE_HIGH_VALUE`, isolating only "high
  value" sites (login pages, authentication flows) rather than providing
  full strict origin isolation.
+ #strong[Firefox 147.0] (January 2026): Ships with Fission enabled.
+ #strong[Bug 2011319] (February 2026): Users report content process
  crashes causing random back-navigation – a regression directly
  attributable to Fission \[28\].
+ #strong[Bug 2011886] (January 23, 2026): Fission switched off in
  release and beta channels. Commit message: "Set isolation strategy to
  ISOLATE\_NONE in all builds except nightly" \[27\].
+ #strong[Bug 2012435] (February 2026, #strong[still open]): Root cause
  identified as content process crashes when isolating sites with
  Fission. The fix remains in progress \[29\].

#strong[Current state (Firefox 152, July 2026).] As reflected in
Mozilla’s `nimbus.fml.yaml` configuration: - Release and beta channels:
`isolationStrategy: 0` (`ISOLATE_NOTHING`) - Nightly and developer
channels: `isolationStrategy: 2` (`ISOLATE_HIGH_VALUE`) - Mozilla’s
Nimbus experiment system may enable Fission for some users in controlled
experiments on release channels.

#strong[Architectural caveat.] A thread on the PrivacyGuides forum noted
that "unprivileged user namespaces are not available to apps on
Android," meaning the kernel-level isolation mechanisms available on
desktop Linux are not directly reproducible on Android \[13\]. Mozilla’s
claim of "the same Site Isolation safeguards" should be understood as
referring to the same architectural approach (process-per-origin
assignment, IPC boundary enforcement, cross-origin data access
restriction) rather than identical kernel-level mechanisms. The precise
kernel-level implementation differences between desktop and mobile
Fission have not been publicly documented by Mozilla as of July 2026,
and this remains the most significant gap in publicly verifiable
information about the mobile architecture.

#strong[To be clear:] Even if Fission were active, it does not replicate
the `isolatedProcess`-based sandbox that Chromium employs. It provides
origin-level process assignment and IPC enforcement, preventing
cross-origin data exfiltration even in the presence of side-channel
attacks. But it does not provide the same post-exploit kernel-level
containment. The relationship between Fission and `isolatedProcess` is
complementary, not substitutive. Moreover, Fission’s current
`ISOLATE_HIGH_VALUE` strategy is narrower than Chromium’s full site
isolation – it only isolates high-value origins rather than every site.

=== 2.4 Is `isolatedProcess` the Complete Picture?
<is-isolatedprocess-the-complete-picture>
A critical framing question is whether the absence of `isolatedProcess`
sandboxing is dispositive in assessing GeckoView’s security posture.
This paper argues it is not, for three reasons:

+ #strong[Complementarity of pre-compromise and post-compromise
  defenses.] Fission’s site isolation reduces the blast radius of a
  compromise (you cannot read other origins’ data), while
  `isolatedProcess` reduces the capabilities of a compromised process
  (you cannot easily access system resources). These are orthogonal
  security properties, and the absence of one does not eliminate the
  value of the other.

+ #strong[The Rust advantage (Section 3).] If the renderer process is
  materially harder to compromise in the first place due to memory-safe
  code, the relative importance of post-compromise containment is
  diminished. A sandbox is irrelevant if the renderer is never
  successfully exploited. However, this calculus must be qualified by
  the current status of Fission. Because site isolation is not active on
  release and beta channels (Section 2.3), a compromised renderer on
  release Firefox for Android does not have origin-level process
  boundaries. A successful exploit could access data across origins
  within the same process, increasing the cross-origin exfiltration risk
  relative to what Fission would provide if active. The Rust memory
  safety advantage reduces the #emph[probability] of compromise, but the
  #emph[blast radius] in the event of a successful exploit is larger
  than would be the case with active site isolation. The paper’s
  original claim that Fission reduces blast radius remains
  architecturally correct, but the protection is not currently available
  in the default release configuration.

+ #strong[Threat-model dependence.] For an attacker whose goal is
  cross-origin data exfiltration (for example, reading your banking
  session from a malicious ad), Fission provides the relevant defense.
  For an attacker whose goal is kernel-level persistence after
  compromising the renderer, `isolatedProcess` provides the relevant
  defense. These address different attack objectives.

#line()

== 3. Memory Safety as a Structural Pre-Compromise Defense
<memory-safety-as-a-structural-pre-compromise-defense>
The most significant structural security advantage of GeckoView over
Chromium is not in sandboxing architecture but in codebase-level
vulnerability resistance. This section examines Firefox’s
industry-leading adoption of the Rust programming language and its
implications for exploit resilience.

=== 3.1 Rust Adoption: Firefox vs. Chromium
<rust-adoption-firefox-vs.-chromium>
Firefox has been systematically rewriting critical components from C++
to Rust. Rust is a memory-safe language that eliminates entire classes
of vulnerabilities (use-after-free, buffer overflows, null pointer
dereferences) at compile time. Major Rust components shipped in Firefox
include:

#align(center)[#table(
  columns: 4,
  align: (col, row) => (auto,auto,auto,auto,).at(col),
  inset: 6pt,
  [Component], [Function], [Shipped], [Significance],
  [#strong[Stylo]],
  [CSS engine],
  [2017],
  [First large-scale Rust component in a major browser; replaced Gecko’s
  C++ CSS system],
  [#strong[RLBox]],
  [Library sandboxing via WebAssembly],
  [2021],
  [Isolates third-party libraries (font parsers, image decoders, audio
  codecs); confines exploits even within the same process],
  [#strong[Necko]],
  [Networking stack],
  [Progressive],
  [Rust-based HTTP/3, DNS over HTTPS, and network protocol
  implementations],
  [#strong[Audio/Video]],
  [Media pipeline],
  [Progressive],
  [Rust-based media decoders and processing pipelines],
  [#strong[WebRender]],
  [GPU rendering],
  [2019 (partial)],
  [Rust-based GPU-accelerated rendering engine],
  [#strong[Glyph/Text]],
  [Text shaping & rendering],
  [Progressive],
  [Rust-based font shaping and text layout],
  [#strong[NSS]],
  [Cryptography],
  [Progressive],
  [Rust-based TLS and cryptographic primitives],
)
]

This has direct security implications. Google’s own security research
has consistently found that approximately 70% of critical-severity
vulnerabilities in Chromium are memory-safety bugs \[14\]. Microsoft’s
Security Response Center has reported comparable figures across its
products \[15\]. By eliminating the possibility of these vulnerability
classes in safe Rust code, Firefox achieves a structural reduction in
exploitable vulnerability density that no amount of kernel sandboxing
can provide.

#strong[Chromium’s Rust adoption remains nascent and experimental.] As
of 2025-2026, Chromium’s codebase remains predominantly C++. The V8
JavaScript engine (the single largest source of critical-severity
vulnerabilities in Chromium) is written entirely in C++. Google’s
experimental "Rust in Chromium" initiative has produced limited
production deployments, primarily in non-critical paths \[16\]. The
Android-specific Chromium rendering pipeline, including the Blink
engine, remains C++-dominant.

The Rust migration is not finished in Firefox either, but the trajectory
is what matters. Each component ported from C++ to Rust removes an
entire class of memory-safety vulnerabilities from that attack surface.
As Mozilla continues porting additional subsystems (networking, media,
graphics, cryptography), the potential for further vulnerability
reduction grows. The gap between Firefox and Chromium in memory-safe
code adoption is widening over time, not narrowing.

#strong[Scope and limitations of Rust-based guarantees.] The Rust
advantage in Firefox is substantial but not absolute, and its scope
deserves precise characterization:

+ #strong[JIT-compiled code is outside Rust’s safety guarantees.] The
  SpiderMonkey JavaScript JIT compiler generates and executes dynamic
  machine code at runtime. This code is not subject to Rust’s
  compile-time memory-safety checks. A vulnerability in the JIT pipeline
  (for example, incorrect bounds computation during inline caching) can
  produce memory corruption regardless of the surrounding code’s
  language. JIT engines are a primary source of critical browser
  vulnerabilities across both Firefox and Chromium \[17\]. RLBox,
  Mozilla’s WebAssembly-based sandboxing, mitigates this by isolating
  certain third-party libraries into sandboxed Wasm compartments \[5\],
  but this does not extend to JIT-generated code.

+ #strong[Logic bugs are not prevented by memory safety.] A correctly
  implemented, memory-safe function can still contain logic errors:
  incorrect state transitions, confused deputy problems, bypassed access
  control checks, or mishandled edge cases. These vulnerabilities are
  not addressed by Rust’s safety guarantees and require different
  mitigation strategies (code review, fuzzing, formal verification).

+ #strong[Cryptographic side channels require language-independent
  defenses.] Constant-time programming, secret-independent memory access
  patterns, and mitigation of microarchitectural side channels (cache
  timing, branch prediction) must be enforced at the implementation
  level regardless of the host language. Rust’s safety guarantees do not
  address side-channel leakage. Notably, Firefox uses NSS (Network
  Security Services) for cryptography, with growing Rust components,
  while Chromium uses BoringSSL (a Google fork of OpenSSL). Both
  libraries require identical care in side-channel-resistant
  implementation.

+ #strong[The Rust migration is incomplete.] Significant portions of the
  GeckoView attack surface remain in C++, including core layout and DOM
  implementation paths. The Rust migration has made progress in
  strategically important areas (CSS, networking, GPU rendering), but a
  complete memory-safe browser engine remains a long-term goal.

=== 3.2 AI-Assisted Hardening Across Both Engines
<ai-assisted-hardening-across-both-engines>
In mid-2025, Mozilla published details of a collaboration with
Anthropic’s red team that used AI-assisted techniques to systematically
audit Firefox for exploitable bugs \[10\]. This effort identified and
fixed latent security issues across the codebase. Mozilla also published
analysis of the dual-use nature of AI in security, noting that the same
techniques defenders use to find vulnerabilities can be weaponized by
attackers at scale \[11\].

AI-assisted hardening is not unique to Mozilla. Google applies
comparable techniques across Chromium and Android, including AI-guided
fuzzing, automated vulnerability discovery via OSS-Fuzz, and ML-based
patch analysis. Both teams operate in the same dual-use landscape. The
significance of Mozilla’s Anthropic collaboration is not that Mozilla
discovered bugs Google could not have found, but that it represents an
investment in a hardening methodology that both vendors will likely need
to sustain as AI-assisted offensive capabilities mature.

These AI-assisted approaches are structurally complementary to a Rust
migration. AI auditing can identify logic bugs, correctness issues, and
complex inter-component vulnerabilities in both Rust and C++ code.
Rust’s compile-time guarantees address a different and largely
orthogonal vulnerability class: memory corruption in safe code paths,
regardless of auditing quality.

=== 3.3 Implications for the Post-Compromise vs. Pre-Compromise Calculus
<implications-for-the-post-compromise-vs.-pre-compromise-calculus>
The combined effect of Rust migration and AI-assisted hardening shifts
the security calculus toward pre-compromise defense. The standard
argument in favor of Chromium’s sandbox assumes that renderer compromise
is inevitable and that post-compromise containment is paramount. But the
inevitability of compromise is itself a function of codebase
vulnerability density:

$ P lr((upright("Successful Exploit"))) eq P lr((upright("Vulnerability Present"))) times P lr((upright("Vulnerability Reachable"))) times P lr((upright("Exploit Successful Given Reachability"))) $

By reducing $P lr((upright("Vulnerability Present")))$ through
memory-safe language adoption, Firefox reduces the overall exploit
probability even before sandboxing is considered. The CVE history of
both browsers consistently shows that the majority of critical-severity
browser vulnerabilities are memory-safety bugs in C++ code \[14\].
Mozilla has not published a component-level breakdown of CVEs by
language, so a direct Rust-versus-C++ comparison within Firefox cannot
be made from public data. However, spot-checking Mozilla security
advisories \[17\] for major Rust components (Stylo, RLBox, WebRender)
since their respective shipping dates yields no severity-critical CVEs
attributable to memory safety in those components. This observation is
consistent with the Rust advantage but should not be treated as a
comprehensive audit. Readers can verify this claim by reviewing the same
advisories.

This advantage compounds over time. Each new Rust component in Firefox
eliminates a vulnerability class from that component permanently. The
cumulative effect of Firefox’s head start in Rust adoption means the
memory-safety gap between the two engines is likely to widen, not
shrink, as both codebases evolve.

=== 3.4 Hardware Mitigations and OS-Level Protections
<hardware-mitigations-and-os-level-protections>
Both Firefox and Chromium benefit from hardware-level exploit
mitigations on modern ARM processors. These include Pointer
Authentication Codes (PAC) for control-flow integrity, Branch Target
Identification (BTI) for indirect branch validation, Memory Tagging
Extension (MTE) on ARMv9 hardware for spatial and temporal memory
safety, and shadow stacks for return address protection. All major
mobile platforms supporting these features apply them to both browser
engines equally, as they are enforced at the OS and hardware level, not
by the browser vendor.

These mitigations are significant but incomplete. The PACman attack
demonstrated that ARM’s Pointer Authentication can be bypassed via
microarchitectural side channels on M1-series processors, exploiting the
limited entropy in unused pointer address bits to forge authenticated
pointers without detection \[20\]. Script-driven JIT engines like
SpiderMonkey and V8 can be leveraged to assemble authenticated gadget
sequences that defeat PAC at the process level. Hardware mitigations
raise the exploitation bar but do not eliminate it, and they do not
change the relative assessment between Chromium and GeckoView, as both
engines operate on identical hardware.

The practical implication is that post-exploit mitigations (both
software-level like `isolatedProcess` and hardware-level like PAC) are
important but interdependent. Hardware mitigations make certain classes
of sandbox escape more difficult, but they cannot compensate for a
structurally higher vulnerability density in the rendering engine
itself.

=== 3.5 Empirical Snapshot: Vulnerability Data from Published Sources
<empirical-snapshot-vulnerability-data-from-published-sources>
This paper does not conduct an independent CVE census (see Scope and
limitations, Section 1), but it relies on published aggregate data from
the vendors themselves and from independent trackers. The following
snapshot contextualizes the architectural arguments in this paper:

#strong[Chromium.] The Chromium project reports that "around 70% of our
serious security bugs are memory safety problems," based on an analysis
of 912 high or critical severity security bugs since 2015 affecting the
Stable channel \[14\]. This data is self-published by Google and is the
most commonly cited statistic on browser memory safety. Google’s Android
team reports comparable figures: "memory safety bugs… account for over
60% of high severity security vulnerabilities" on the platform, and the
Chrome team’s GWP-ASan data confirms the same pattern \[22\]. Google
Project Zero’s annual tracking of exploited-in-the-wild 0-days
consistently shows that memory corruption (use-after-free,
out-of-bounds) constitutes the overwhelming majority of exploitations
across all targets, including browsers \[23\].

#strong[Firefox.] Mozilla maintains a security advisory page listing all
fixed vulnerabilities with severity ratings \[17\], but does not publish
aggregate breakdowns comparable to Chromium’s 912-bug analysis. Mozilla
has not released a public study classifying its CVE inventory by root
cause category (memory safety vs. logic vs. other). This is a gap in the
public evidence base. Individual advisory review suggests that Firefox’s
CVE distribution follows a similar pattern to Chromium’s for its C++
components, but this cannot be verified from Mozilla’s published data
alone. The Rust components shipped in Firefox (Stylo since 2017, RLBox
since 2021, WebRender since 2019) have not produced severity-critical
memory-safety CVEs in Mozilla’s published advisories as of July 2026,
which is consistent with the expected benefit of memory-safe language
adoption but falls short of a statistically rigorous demonstration.

#strong[Summary.] The available data supports two conclusions: (a)
memory safety bugs dominate browser vulnerability landscapes across both
engines, and (b) Mozilla’s Rust components have a clean track record
since shipping, but the sample size and public documentation are
insufficient for a quantitative cross-browser comparison. Architectural
arguments about Rust’s security value (Section 3.1-3.3) should be
evaluated in light of this limited empirical basis.

#line()

== 4. Extension Architecture as Security Infrastructure
<extension-architecture-as-security-infrastructure>
GrapheneOS dismisses extension-based security as "privacy theater" and
equates content filtering with AntiVirus-style "enumeration of badness"
\[1\]. This section argues that this characterization conflates distinct
security mechanisms and overlooks the structural security properties of
Firefox’s extension architecture.

=== 4.1 Network-Layer Content Interception
<network-layer-content-interception>
The WebExtension content-blocking API allows extensions such as uBlock
Origin to parse network requests against declarative filter rules (DNR,
Declarative Net Request) and block resources #emph[before] they are
fetched or executed. The conceptual flow:

```
[ Network Payload ] -> [ WebExtension Filter ] -> [ Browser Engine ]
                            |
                    (Blocked at network layer)
```

This is structurally distinct from AntiVirus scanning. Key differences:

+ #strong[Timing.] AntiVirus typically scans files after they are
  written to disk and before execution. WebExtension content blocking
  intercepts requests at the network layer, before the payload is
  fetched and before any code execution occurs. The exploit never enters
  the device’s memory.

+ #strong[Attack surface reduction.] Every blocked request reduces the
  volume of untrusted code processed by the rendering engine. This is a
  direct reduction in the attack surface exposed to the network, not a
  detection-after-delivery model.

+ #strong[Determinism.] Declarative filter rules operate on
  deterministic pattern matching (URL patterns, domain names, resource
  types), not heuristics or behavioral analysis. There is no
  false-negative risk from an unrecognized exploit payload. If the
  payload’s delivery infrastructure is blocked, the payload never
  arrives.

The limitation that GrapheneOS correctly identifies (that filter lists
must enumerate known malicious patterns and cannot block novel delivery
vectors) is real. But this limitation is not dispositive. Zero-day
exploit delivery in practice frequently relies on known malicious
infrastructure (command-and-control domains, exploit kit landing pages,
compromised ad networks) that filter lists can and do block. The
argument that "enumerating badness" is futile assumes that attackers can
instantiate novel delivery infrastructure for every target at zero cost.
That assumption does not hold for mass-market or spray-and-pray
exploitation campaigns.

=== 4.2 Extension-to-Extension Isolation
<extension-to-extension-isolation>
Firefox’s WebExtension architecture enforces strict isolation boundaries
between extensions that are more restrictive than Chromium’s in several
dimensions:

+ #strong[No direct inter-extension communication.] Firefox extensions
  cannot directly call each other’s APIs, access each other’s storage,
  or inspect each other’s state. Inter-extension communication is only
  possible through explicit, user-visible channels (`storage.onChanged`
  events for same-origin storage, or `runtime.onMessageExternal` with
  explicit `externally_connectable` manifest declarations).

+ #strong[Storage partition isolation.] Each extension’s local storage,
  IndexedDB, and other persistent storage are cryptographically
  partitioned by extension ID. Extension A cannot read Extension B’s
  stored data even if both are installed in the same browser profile.

+ #strong[Content script confinement.] Content scripts injected by
  extensions run in isolated worlds within the page’s process. They have
  no access to the page’s JavaScript objects or DOM APIs unless
  explicitly granted. This prevents a compromised page from leveraging
  an extension’s content script as a privilege escalation vector.

The security implication is that a compromised extension (whether
through a malicious update, a supply-chain attack on the extension’s
dependencies, or exploitation of an extension API vulnerability) cannot
easily pivot to compromise other extensions. A compromised
content-blocking extension like uBlock Origin cannot exfiltrate data
from a password manager extension’s storage. This #strong[blast radius
containment] is a structural security property of the extension
architecture, not a privacy feature.

In Chromium’s extension architecture, similar isolation principles
apply, but the broader API surface for inter-extension messaging and the
availability of native messaging hosts (which can bridge extensions to
system-level processes) create a larger lateral-movement surface for a
compromised extension \[18\].

=== 4.3 The Limitations of an Extension-Based Approach
<the-limitations-of-an-extension-based-approach>
This analysis should not be read as an argument that extension-based
defenses are sufficient. The well-documented limitations remain:

+ #strong[Reactive enumeration.] Filter lists must be maintained and
  updated. A novel exploit delivery vector that does not match known
  infrastructure patterns will not be blocked.

+ #strong[Fingerprinting risk.] Custom extensions and configurations
  increase browser distinctiveness. This risk is continuous, not binary.
  The marginal fingerprinting cost of a widely-used extension with
  default settings is lower than GrapheneOS’s framing suggests.

+ #strong[Performance overhead.] Content filtering and script blocking
  consume CPU and memory resources.

Extension-based defenses and kernel-level sandboxing are complementary
layers operating at different points in the exploit chain. Dismissing
one layer as "privacy theater" overlooks its genuine security value.

=== 4.4 Manifest V3 and Extension API Surface
<manifest-v3-and-extension-api-surface>
The transition from Manifest V2 to Manifest V3 in Chromium has security
implications that intersect with the content-blocking discussion.
Manifest V3 restricts certain extension APIs that content blockers rely
on: the `webRequest` blocking API is replaced by the more limited
`declarativeNetRequest` API, which imposes caps on dynamic filter rule
counts and restricts the timing of rule evaluation. These changes were
justified by Google on security and performance grounds, specifically
citing the principle of least privilege \[21\].

Firefox continues to support Manifest V2 extension APIs, including full
`webRequest` blocking. This has two relevant effects for this analysis:

+ #strong[More effective content blocking.] uBlock Origin on Firefox can
  enforce dynamic, user-created filter rules and larger block lists
  without hitting API-imposed limits. On Chromium-based browsers
  (including Vanadium), the same extension is restricted to a subset of
  its filtering capabilities.

+ #strong[Larger extension API surface.] Maintaining support for the V2
  API surface means Firefox exposes a broader set of extension
  capabilities that, if compromised, could be leveraged by a malicious
  extension. This is a real trade-off, not an unqualified security
  advantage.

The net assessment depends on whether one views the extension API
surface primarily as attack surface or as defense infrastructure.
GrapheneOS’s position falls firmly in the former camp \[1\]. This paper
argues that the value of network-layer content interception as a
pre-compromise defense justifies the API surface exposure for users who
choose to deploy extensions. For users who do not use extensions, the
API surface difference is irrelevant.

#line()

== 5. Privacy Architecture Overlap with Security Models
<privacy-architecture-overlap-with-security-models>
Security and privacy are frequently analyzed as separate domains, but in
practice they intersect at a critical point: the reconnaissance phase of
targeted exploitation. Privacy controls that disrupt device
fingerprinting, cross-site tracking, and behavioral profiling directly
impede an attacker’s ability to identify, profile, and target specific
individuals. This section examines how each engine family addresses this
intersection.

=== 5.1 Firefox’s Structural Privacy Defenses
<firefoxs-structural-privacy-defenses>
Firefox on Android deploys multiple structural privacy protections as
built-in defaults. Several operate at the network stack or browser
engine level, not as extension-based configurations:

#strong[Total Cookie Protection (dynamic first-party isolation).]
Firefox partitions cookies and site storage by the top-level site. This
prevents cross-site tracking via cookie synchronization, storage access,
and state sharing. A tracker embedded in `site-a.com` cannot read the
cookie it set when embedded in `site-b.com`, because the cookie jar is
partitioned by the top-level origin. This is implemented at the network
stack level and is enabled by default \[19\].

#strong[Enhanced Tracking Protection (ETP).] Firefox blocks known
tracking resources, fingerprinting scripts, and cryptominers by default
using a combination of the Disconnect list and built-in heuristic
detection. ETP operates at the network level before resources are loaded
or executed.

#strong[Multi-Account Containers.] Tabs can be assigned to isolated
containers, each with separate cookie jars, storage, browsing history,
and site state. This provides user-level identity separation (for
example, work versus personal browsing) that operates orthogonally to
site-level isolation. A tracking script in a "work" container cannot
access data from a "personal" container, even if both are open
simultaneously.

#strong[Anti-fingerprinting protections.] Firefox includes
fingerprinting-resistant APIs derived from the Tor Browser project,
covering canvas fingerprinting, WebGL, audio context fingerprinting,
font enumeration, and battery status. These are less extensive than Tor
Browser’s full fingerprinting resistance, but they provide baseline
defense against passive fingerprinting without requiring user
configuration.

#strong[DNS-over-HTTPS (DoH) with strict mode.] Firefox can encrypt DNS
queries, preventing DNS-level surveillance, tampering, and redirection.
This is a network-level privacy protection that also prevents certain
classes of DNS-based tracking.

=== 5.2 Vanadium’s Privacy Roadmap
<vanadiums-privacy-roadmap>
GrapheneOS’s Vanadium project has historically prioritized security
hardening over privacy features. The stated privacy roadmap includes
\[1\]:

- #strong[Always-incognito mode] (no persistent browsing state)
- #strong[Improved state partitioning] beyond current cookie isolation
- #strong[Network Isolation Keys], dividing connection pools, caches,
  and other network state based on site origin

GrapheneOS acknowledges that this work is "currently in a very early
stage" and that "at the moment, the only browser with any semblance of
privacy is the Tor Browser" \[1\]. As of July 2026, Vanadium’s
structural privacy protections remain less mature than what Firefox
ships as defaults.

=== 5.3 The Reconnaissance Disruption Argument
<the-reconnaissance-disruption-argument>
The attack chain for a targeted exploitation campaign often begins with
data collection:

```
[ Data Brokers / Ad Networks ] -> [ Fingerprinting Profiles ] -> [ Targeted Phishing ] -> [ Exploit Delivery ]
```

Disrupting the left side of this chain is a legitimate security
strategy. An attacker who cannot reliably identify and profile a target
cannot deliver a tailored exploit. This is not privacy-theater. It is
threat-model-appropriate defense for users whose primary risk is not
state-sponsored zero-click attacks but rather targeted exploitation
enabled by data-broker profiling.

GrapheneOS’s position does not dispute this connection but questions the
efficacy of client-side anti-fingerprinting: "Most privacy features for
browsers are privacy theater without a clear threat model and these
features often reduce privacy by aiding fingerprinting and adding more
state shared between sites" \[1\]. This critique has merit for poorly
implemented anti-fingerprinting measures, but it does not apply equally
to all privacy features. Total Cookie Protection, for example, does not
increase fingerprinting surface. It partitions state, which is a
strictly additive privacy gain with no fingerprinting cost.

#line()

== 6. The Systemic Risk of Engine Monoculture
<the-systemic-risk-of-engine-monoculture>
Beyond the architectural comparison between individual engines lies a
systemic security question: what are the aggregate security properties
of a browser ecosystem dominated by a single engine?

=== 6.1 Market Concentration and Attack Incentives
<market-concentration-and-attack-incentives>
As of 2025-2026, Chromium-based browsers account for the vast majority
of global mobile browser usage. This market concentration creates a
structural security risk. A single vulnerability in the Chromium
rendering engine, V8 JavaScript engine, or Mojo IPC layer potentially
threatens billions of devices simultaneously.

The concept of software monoculture as a systemic vulnerability was
articulated by Geer et al. \[7\], who argued that homogeneity in
critical software infrastructure concentrates attack value and reduces
the diversity required for ecosystem resilience. In the browser context,
a zero-day vulnerability in Chromium’s V8 engine simultaneously affects
Google Chrome, Microsoft Edge, Samsung Internet, Brave, Opera, and
hardened forks like Vanadium, across every platform they run on. This
concentration of value creates powerful incentives for exploit
developers (both commercial zero-day brokers and advanced persistent
threats) to invest in Chromium-specific research.

=== 6.2 Codebase Diversity as Macro-Level Circuit Breaker
<codebase-diversity-as-macro-level-circuit-breaker>
GeckoView operates on an entirely independent codebase: the Gecko
rendering engine and SpiderMonkey JavaScript engine. An exploitation
payload engineered for a Chromium-specific memory-corruption
vulnerability or sandbox-escape technique is structurally inert when
processed by GeckoView. This independence provides what this paper terms
a #strong[macro-level circuit breaker]. Localized environments running
GeckoView are automatically insulated from exploit campaigns targeting
the Chromium codebase.

The security literature on diversity as a defense mechanism supports
this principle. The use of diverse, functionally equivalent
implementations reduces the likelihood that a single attack technique
compromises all targets \[7\], \[8\]. This is an operational security
principle employed in critical infrastructure, cryptographic
implementations, and defense-in-depth architectures. The browser
ecosystem’s effective monoculture is an anomaly in security engineering,
not a best practice.

=== 6.3 The Dual-Engine Requirement Reframed
<the-dual-engine-requirement-reframed>
GrapheneOS objects that GeckoView is not a WebView implementation,
meaning Firefox on Android must be deployed alongside the platform’s
Chromium-based WebView, resulting in "the remote attack surface of two
separate browser engines instead of only one" \[1\].

#strong[This objection requires substantial reframing.] It describes an
Android platform architectural constraint and a design choice by
GrapheneOS, not a deficiency of GeckoView.

Android’s platform architecture mandates a system WebView component that
is independent of the user’s chosen browser. On GrapheneOS, this WebView
is Vanadium (Chromium-based) regardless of which browser the user
selects \[2\]. The dual-engine concern is asymmetric:

#align(center)[#table(
  columns: 2,
  align: (col, row) => (auto,auto,).at(col),
  inset: 6pt,
  [User’s Browser Choice], [Engine(s) Present],
  [Vanadium (or any Chromium browser)],
  [Chromium (browser) + Chromium (WebView) \= single engine, two
  instances],
  [Firefox (GeckoView)],
  [Gecko (browser) + Chromium (WebView) \= two engines],
)
]

The dual-engine state exists because Android’s platform design enforces
a separate WebView engine, and because that WebView is Chromium-based.
The concern is entirely a function of these two platform-level
decisions. If GrapheneOS were to substitute a GeckoView-based WebView
for Vanadium’s WebView, the dual-engine concern would vanish.
Conversely, if an Android user runs only Chromium-based browsers, they
still have two copies of the Chromium engine on their device (browser +
WebView), which is not commonly flagged as a security concern.

#strong[The dual-engine "problem" is a platform design constraint, not a
Firefox deficiency.] The security impact depends on the user’s threat
model:

- A user whose primary concern is aggregate attack surface may prefer a
  Chromium-only configuration to minimize engine diversity.
- A user whose primary concern is monoculture risk may prefer a
  GeckoView browser even at the cost of dual-engine deployment.
- For both configurations, the WebView engine is present regardless of
  browser choice. The marginal additional attack surface of adding
  GeckoView is the Gecko engine itself. This is a real addition, but it
  must be weighed against the monoculture risk reduction that diversity
  provides.

#line()

== 7. Critical Examination of GrapheneOS’s Claims Against Gecko-Based
Browsers
<critical-examination-of-grapheneoss-claims-against-gecko-based-browsers>
GrapheneOS maintains a well-documented position advising against
Gecko-based browsers, rooted in specific architectural and operational
concerns \[1\]. This section examines each of those claims against
current evidence (as of July 2026), identifying where they are
substantiated, where they have aged, and where they reflect divergent
threat-model priorities rather than objective security deficits.

=== 7.1 Claim: "Firefox does not have internal sandboxing on Android"
<claim-firefox-does-not-have-internal-sandboxing-on-android>
#strong[Status: Partially outdated.]

Firefox on Android does not implement Android’s `isolatedProcess`
mechanism for its child processes. This component of GrapheneOS’s claim
remains technically accurate \[1\]. The `isolatedProcess` attribute is a
declarative manifest flag, and its absence represents a deliberate or
resource-constrained decision by Mozilla.

The broader claim that Firefox has "no internal sandboxing" conflates
the absence of one specific mechanism with the absence of all
sandboxing. Firefox 147 shipped Site Isolation (Fission) for Android,
but it was rolled back in 147.0.2 due to content process crashes and
remains disabled on release and beta channels as of Firefox 152 (Section
2.3). Fission provides origin-level process boundaries and restricts
cross-origin data access via IPC enforcement, but this protection is
currently only available on nightly and developer builds. Additionally,
GeckoView’s multi-process architecture provides a privileged parent
process and separate content processes.

The claim conflates "no `isolatedProcess`-based sandboxing" with "no
internal sandboxing" generally. These are materially different
assertions, and the former does not imply the latter.

=== 7.2 Claim: "Gecko-based browsers like Firefox are much more
vulnerable to exploitation"
<claim-gecko-based-browsers-like-firefox-are-much-more-vulnerable-to-exploitation>
#strong[Status: No longer supported by current evidence.]

This claim requires separate evaluation for two components: (a)
vulnerability density in the codebase, and (b) the difficulty of
exploiting residual vulnerabilities given available mitigations.

On component (a), Firefox’s industry-leading Rust adoption (Section 3.1)
provides compile-time memory-safety guarantees that Chromium’s
predominantly C++ codebase does not have. Given that roughly 70% of
critical-severity browser vulnerabilities are memory-safety bugs \[14\],
a codebase that eliminates these vulnerability classes in critical paths
has a structurally lower vulnerability density. Mozilla’s 2026
AI-assisted hardening effort \[10\] has further reduced the residual
vulnerability count.

On component (b), the absence of `isolatedProcess` on Android means that
a successfully exploited memory corruption vulnerability faces weaker
post-exploit containment than on Chromium. This is a real limitation,
but its overall risk contribution is attenuated by the lower probability
of initial compromise (due to memory safety). The overall exploit
probability
($P lr((upright("Compromise"))) times P lr((upright("Successful Exploitation Given Compromise")))$)
is not obviously higher for GeckoView, because the two factors move in
opposite directions.

#strong[GrapheneOS’s framing that Firefox is "much more vulnerable"
conflates a difference in post-compromise architecture with a difference
in overall exploit risk.] These are distinct metrics, and the available
evidence does not support the categorical claim.

=== 7.3 Claim: "Even in the desktop version, Firefox’s sandbox is still
substantially weaker (especially on Linux) and lacks full support for
isolating sites"
<claim-even-in-the-desktop-version-firefoxs-sandbox-is-still-substantially-weaker-especially-on-linux-and-lacks-full-support-for-isolating-sites>
#strong[Status: Requires platform-specific assessment; partially
outdated.]

This claim reflected an accurate description of the desktop state when
it was written \[1\]. Desktop sandboxing is platform-specific, and the
validity of GrapheneOS’s claim now varies by operating system.

#strong[Windows.] Firefox on Windows has reached Content Process Sandbox
Level 9 across all release channels as of early 2026 \[24\]. This is the
highest sandbox level defined. Level 9 includes total Win32k system call
lockdown (closing a historically major sandbox-escape vector),
zero-trust file system access (deny-by-default, with explicit whitelists
only for required resources), and third-party DLL load blocking. The GPU
process sandbox operates at Level 2, isolating graphics driver access
from the OS. Mozilla’s sandbox architecture on Windows uses Job objects,
restricted access tokens, integrity levels, and Win32k lockdown – the
same primitives that Chromium’s Windows sandbox uses. The gap on this
platform has effectively closed. Users can verify their sandbox level by
checking the Content Process Sandbox Level entry in `about:support`.

#strong[Linux.] Firefox on Linux ships Content Process Sandbox Level 6,
which provides seccomp-BPF syscall filtering with default-deny for
ioctl, filesystem read/write brokering via a separate broker process,
network and socket restrictions, chroot jail, and unprivileged user
namespaces when available \[24\]. The Linux sandbox uses a different
mechanism than Windows because the platform provides different
primitives (namespace isolation, seccomp-BPF, AppArmor/SELinux).
Chromium’s Linux sandbox also uses seccomp-BPF and namespaces, but has a
more finely restricted syscall policy in some areas. Without an updated
side-by-side technical comparison, the claim that Firefox’s Linux
sandbox is "substantially weaker" cannot be verified or refuted from
public documentation.

#strong[macOS.] Firefox on macOS uses a whitelist-based sandbox policy
at Level 3, which denies all system access by default and explicitly
permits only required resources (specific file system paths,
WindowServer, microphone, named sysctls, IOKit properties) \[24\]. Write
access to the entire file system is blocked, along with inbound/outbound
network I/O, exec, fork, printing, and camera access. This is
architecturally comparable to Chromium’s macOS sandbox, which also uses
the macOS Sandbox framework with a deny-by-default policy.

#strong[Site isolation (Fission).] The claim that Firefox "lacks full
support for isolating sites" is clearly outdated. Fission has been
shipping on desktop Firefox since version 95 (December 2021) with
continuous refinements since \[3\], \[5\].

#strong[Without an updated, platform-specific technical comparison from
GrapheneOS or an independent researcher, the blanket claim that
Firefox’s desktop sandbox is "substantially weaker" cannot be
sustained.] On Windows, the evidence suggests parity. On Linux and
macOS, the comparison requires more detailed analysis than either party
has published.

=== 7.4 Claim: "Achieving browser privacy through piling on extensions
is privacy theater"
<claim-achieving-browser-privacy-through-piling-on-extensions-is-privacy-theater>
#strong[Status: A legitimate philosophical disagreement with important
nuance.]

GrapheneOS argues that "most privacy features for browsers are privacy
theater without a clear threat model" and that "every change you make
results in you standing out from the crowd" \[1\]. This position
contains internal tensions that require examination:

+ #strong[The AntiVirus analogy is inapt.] GrapheneOS equates
  content-filtering extensions with AntiVirus software, arguing that
  both involve "enumerating badness." The timing and mechanism differ
  fundamentally. AntiVirus scans files on disk after delivery.
  WebExtension content blocking intercepts requests at the network layer
  #emph[before] any payload reaches the rendering engine. Blocking
  before delivery is categorically different from detecting after
  compromise.

+ #strong[Fingerprinting distinctiveness is a continuous, not binary,
  property.] GrapheneOS’s claim that any extension-based change
  increases fingerprinting surface is theoretically correct, but the
  practical fingerprinting cost of deploying widely-used extensions with
  default settings is lower than the framing suggests. A user running
  Firefox with uBlock Origin’s default filter lists, Total Cookie
  Protection, and ETP is not uniquely fingerprintable. They belong to a
  substantial population of similarly configured users.

+ #strong[Content blocking reduces attack surface directly, independent
  of privacy.] Blocking known exploit-delivery domains at the network
  layer reduces the volume of untrusted code reaching the rendering
  engine. This is a security benefit (not merely a privacy benefit) and
  it operates regardless of the quality of the browser’s
  anti-fingerprinting protections.

The core critique (that enumeration-based approaches cannot prevent
novel zero-day delivery vectors) remains valid. But this is a limitation
shared by all detection-based security mechanisms, including the
`isolatedProcess` sandbox (which cannot prevent a novel renderer
exploit, only contain it after exploitation). The two approaches are
complementary. Content blocking reduces the volume of exploit attempts
reaching the renderer, while sandboxing contains those that succeed.

=== 7.5 Claim: "Firefox on Android must be deployed alongside
Chromium-based WebView, creating dual-engine attack surface"
<claim-firefox-on-android-must-be-deployed-alongside-chromium-based-webview-creating-dual-engine-attack-surface>
#strong[Status: Describes a platform constraint, not a Firefox
deficiency.]

This claim is factually correct as a description of Android’s current
platform architecture. Its framing as a Firefox security deficiency is
logically flawed:

- The dual-engine state is enforced by Android’s platform design, which
  mandates a system WebView independent of the browser. It is not a
  design choice by Mozilla.
- On GrapheneOS, the WebView is Vanadium (Chromium-based) regardless of
  the user’s browser choice. This is a design decision by GrapheneOS.
- The dual-engine concern would be eliminated if (a) Android’s platform
  architecture permitted a user-selectable WebView engine, or (b)
  GrapheneOS substituted a GeckoView-based WebView for Vanadium.
- The dual-engine state is symmetric in an important sense. A
  Vanadium-only user still has two copies of the Chromium engine
  (browser + WebView), which is not flagged as a security concern.

Does adding GeckoView increase aggregate attack surface beyond what the
platform already requires? Yes, unavoidably. But this incremental
increase must be weighed against the monoculture risk reduction and
architectural diversity that GeckoView provides (Section 6). A user who
values diversity as a defense-in-depth measure may rationally accept the
incremental attack surface of a second engine in exchange for the
structural protection against Chromium-specific zero-day campaigns.

=== 7.6 Summary Assessment
<summary-assessment>
The following table summarizes the status of each major GrapheneOS
claim:

#align(center)[#table(
  columns: 3,
  align: (col, row) => (auto,auto,auto,).at(col),
  inset: 6pt,
  [Claim], [Assessment], [Rationale],
  ["No `isolatedProcess` sandboxing"],
  [#strong[Substantiated]],
  [GeckoView does not use `isolatedProcess` \[1\]],
  ["No internal sandboxing on Android"],
  [#strong[Partially outdated]],
  [Fission shipped Jan 2026, rolled back; active nightly/dev only
  \[27\]-\[30\]; multi-process architecture exists],
  ["Much more vulnerable to exploitation"],
  [#strong[Not supported by current evidence]],
  [Rust memory safety, AI hardening, Fission landing; post-compromise
  vs. pre-compromise conflation],
  ["Desktop sandbox substantially weaker"],
  [#strong[Platform-dependent; Windows at parity, Linux/macOS
  unverified]],
  [Windows Level 9 \[24\], \[25\]; Linux Level 6; Fission shipped 2021;
  no current platform-specific comparison from GrapheneOS],
  ["Extension privacy is theater"],
  [#strong[Philosophical disagreement]],
  [Content blocking provides genuine pre-delivery interception; anti-AV
  analogy is structurally inapt],
  ["Dual-engine attack surface"],
  [#strong[Platform constraint, not Firefox deficiency]],
  [Enforced by Android; symmetric concern; design choice by GrapheneOS],
)
]

#line()

== 8. Conclusion and Threat Model Matrix
<conclusion-and-threat-model-matrix>
The security properties of mobile browser engines cannot be reduced to a
single metric or a categorical "secure vs. insecure" classification.
Each architecture makes tradeoffs that align with different threat-model
priorities. The categorical assertion that Gecko-based browsers are
non-viable on Android is not supported by current evidence. But the
counter-assertion that GeckoView has achieved parity with Chromium’s
sandboxing on mobile is also not supported.

The following matrix summarizes the evaluated properties across the full
threat landscape:

#align(center)[#table(
  columns: 3,
  align: (col, row) => (auto,auto,auto,).at(col),
  inset: 6pt,
  [Threat Profile Vector], [Chromium Architecture (Vanadium)],
  [GeckoView Architecture (Firefox)],
  [#strong[Primary Mitigation Philosophy]],
  [Post-compromise kernel containment],
  [Pre-compromise memory safety + content interception],
  [#strong[Sandboxing Mechanism]],
  [Kernel-level (`isolatedProcess`) UID isolation],
  [Application-level process spawning + Fission origin isolation],
  [#strong[Site Isolation (Mobile)]],
  [Strict site isolation with kernel enforcement \[1\]],
  [Fission shipped Firefox 147 (Jan 2026), rolled back in 147.0.2;
  disabled on release/beta channels as of Firefox 152; active on nightly
  and developer channels only \[27\]-\[30\]; kernel mechanism differs
  from desktop \[12\]],
  [#strong[Post-Exploit Containment]],
  [Strong (UID isolation, CFI, SSP, seccomp-BPF on desktop)],
  [Limited by absence of `isolatedProcess` \[1\]],
  [#strong[Memory Safety]],
  [Predominantly C++ (V8, Blink); Rust experimental \[14\], \[16\]],
  [Extensive Rust adoption (Stylo, RLBox, Necko, WebRender); C++ legacy
  paths remain],
  [#strong[Memory Safety Trajectory]],
  [Rust adoption nascent; gap with Firefox widening],
  [Continued porting of subsystems; compounding vulnerability reduction
  over time],
  [#strong[Pre-Delivery Interception]],
  [Optional via extensions; built-in content filtering available],
  [Built-in ETP + WebExtension content blocking (uBlock Origin)],
  [#strong[Extension Isolation]],
  [Broader inter-extension messaging; native messaging hosts \[18\]],
  [Stricter isolation; no direct inter-extension access],
  [#strong[Monoculture Risk Exposure]],
  [High (primary target of global exploit pipelines)],
  [Low (immune to Chromium-specific exploits)],
  [#strong[Privacy Architecture (Shipped)]],
  [Basic; privacy roadmap in early stages \[1\]],
  [Total Cookie Protection, ETP, Containers, anti-fingerprinting, DoH
  \[19\]],
  [#strong[Privacy Architecture (Maturity)]],
  [Roadmap only; "very early stage" \[1\]],
  [Mature defaults; enabled by default],
  [#strong[Dual-Engine Requirement]],
  [Single engine (WebView + browser both Chromium)],
  [Dual engine (GeckoView + Chromium WebView required by platform)],
)
]

=== 8.1 Threat Model Alignment
<threat-model-alignment>
- #strong[For users facing targeted, state-sponsored zero-click
  exploitation] where kernel-level containment after compromise is
  critical, the Chromium/Vanadium architecture (with its
  `isolatedProcess` sandboxing, site isolation, and CFI) provides
  objectively stronger post-exploit defenses. This remains the strongest
  use case for a Chromium-based browser on Android.

- #strong[For users facing mass surveillance, corporate data mining, and
  widespread exploit campaigns targeting the Chromium monoculture],
  GeckoView’s independence offers structural protections that Chromium
  derivatives cannot provide, even with hardening. The Rust-based memory
  safety and network-layer content interception provide pre-compromise
  defenses that operate regardless of the kernel sandbox quality.

- #strong[For privacy-conscious users concerned with
  reconnaissance-phase disruption], Firefox’s structural privacy
  protections (Total Cookie Protection, ETP, Containers) are materially
  more mature than Vanadium’s privacy roadmap, which remains in early
  development \[1\].

- #strong[For security-conscious users on GrapheneOS specifically], the
  OS-level hardening applies to all applications. GeckoView does not
  benefit from `isolatedProcess` regardless of the host OS, and the
  dual-engine deployment increases aggregate attack surface. Users in
  this category should evaluate whether the monoculture risk reduction
  and memory safety benefits of GeckoView outweigh the weaker
  post-exploit containment.

#line()

== Methodology Note
<methodology-note>
This analysis is based on publicly available documentation accessed in
July 2026. Primary sources include GrapheneOS’s official usage guide and
features documentation \[1\], \[2\]; Mozilla’s architecture
documentation and engineering blog posts \[3\], \[4\], \[5\], \[10\];
peer-reviewed security literature \[6\], \[7\], \[8\]; Android platform
documentation \[9\]; community release announcements \[12\]; and
technical community discussion \[13\].

#strong[Verified claims] are those confirmed by at least one primary
source. #strong[Uncertain claims] are noted explicitly. The most
significant remaining gap is the absence of detailed technical
documentation from Mozilla on how Fission’s kernel-level isolation
mechanisms on Android differ from the desktop implementation. Mozilla’s
engineering team has not published an architecture document comparable
to Chromium’s Site Isolation paper \[6\].

#strong[This paper does not assess] the iOS versions of either browser,
as iOS WebKit requirements fundamentally alter the sandboxing landscape.
It also does not provide a comprehensive assessment of desktop
sandboxing, except where desktop architectures are referenced for
comparison.

#strong[Scope classification.] This analysis is primarily an
architectural threat-modeling comparison, not an empirical vulnerability
census. Where aggregate CVE data is cited (Section 3.5), it is drawn
from vendor-published statistics and independent trackers, with
limitations explicitly noted. Readers who need a direct quantitative
comparison of CVE counts between Chromium and Firefox should consult the
respective vendor advisory pages \[14\], \[17\]. The authors have made
no attempt to produce an independent CVE inventory, as the
methodological challenges (differential disclosure practices, severity
rating inconsistencies, and the absence of Mozilla-published root-cause
classifications) would produce results of limited reliability.

#line()

== References
<references>
\[1\] GrapheneOS, "Usage: Web Browsing." \[Online\]. Available:
#link("https://grapheneos.org/usage#web-browsing")[https://grapheneos.org/usage\#web-browsing].
Accessed: Jul. 2026.

\[2\] GrapheneOS, "Features." \[Online\]. Available:
#link("https://grapheneos.org/features"). Accessed: Jul. 2026.

\[3\] A. Gakhokidze, "Introducing Firefox’s new Site Isolation Security
Architecture," Mozilla Hacks, May 2021. \[Online\]. Available:
#link("https://hacks.mozilla.org/2021/05/introducing-firefox-new-site-isolation-security-architecture/")

\[4\] R. Jesup, "Process Isolation Architecture in the Gecko Rendering
Engine," Mozilla Wiki. \[Online\]. Available:
#link("https://mozilla.github.io/firefox-browser-architecture/text/0012-process-isolation-in-firefox.html")

\[5\] Mozilla Wiki, "Project Fission." \[Online\]. Available:
#link("https://wiki.mozilla.org/Project_Fission")[https://wiki.mozilla.org/Project\_Fission]

\[6\] C. Reis, G. Moteva, and S. Gribble, "Site Isolation: Process
separation for web sites within the browser," in #emph[Proc. 28th USENIX
Security Symp.], Santa Clara, CA, USA, 2019, pp. 1461-1478.

\[7\] D. Geer, R. Bace, P. Gutmann, P. Metzger, C. P. Pfleeger, J. S.
Quarterman, and B. Schneier, "CyberInsecurity: The Cost of Monopoly,"
Computer & Communications Industry Association (CCIA), 2003.

\[8\] K. Thompson, "Reflections on Trusting Trust," #emph[Commun. ACM],
vol. 27, no. 8, pp. 761-763, Aug. 1984.

\[9\] Android Open Source Project, "Isolated Process," Android
Developers. \[Online\]. Available:
#link("https://developer.android.com/guide/topics/manifest/service-element#isolatedProcess")[https://developer.android.com/guide/topics/manifest/service-element\#isolatedProcess]

\[10\] Mozilla, "Hardening Firefox Together with Anthropic’s Red Team,"
Mozilla Blog, 2025. \[Online\]. Available:
#link("https://blog.mozilla.org/en/firefox/hardening-firefox-anthropic-red-team/")

\[11\] Mozilla, "AI Security and Zero-Day Vulnerabilities," Mozilla
Blog, 2025. \[Online\]. Available:
#link("https://blog.mozilla.org/en/privacy-security/ai-security-zero-day-vulnerabilities/")

\[12\] Mozilla, "Firefox for Android 147.0 Release Notes," Jan. 2026.
(Current as of Firefox 152, Jul. 2026). \[Online\]. Available:
#link("https://www.mozilla.org/en-US/firefox/android/147.0/releasenotes/")

\[13\] PrivacyGuides Community, "Site Isolation (Fission) now appears to
be active in Firefox on Android," PrivacyGuides Discourse, Jan. 2026.
\[Online\]. Available:
#link("https://discuss.privacyguides.net/t/site-isolation-fission-now-appears-to-be-active-in-firefox-on-android/34899")

\[14\] Chromium Project, "Memory Safety." \[Online\]. Available:
#link("https://www.chromium.org/Home/chromium-security/memory-safety/")
. Accessed: Jul. 2026.

\[15\] M. Miller, "Trends and Challenges in the Vulnerability Mitigation
Landscape," USENIX Enigma 2019. \[Online\]. Available:
#link("https://www.usenix.org/conference/enigma2019/presentation/miller")

\[16\] Chromium Project, "Rust in Chromium." \[Online\]. Available:
#link("https://chromium.googlesource.com/chromium/src/+/main/docs/security/rust.md")
. Accessed: Jul. 2026.

\[17\] Mozilla Security Blog, "Security Advisories," various years.
\[Online\]. Available:
#link("https://www.mozilla.org/en-US/security/advisories/") . Accessed:
Jul. 2026.

\[18\] Chrome Developer Documentation, "Native Messaging." \[Online\].
Available:
#link("https://developer.chrome.com/docs/extensions/mv3/nativeMessaging/")
. Accessed: Jul. 2026.

\[19\] Mozilla, "Total Cookie Protection," Mozilla Security Blog.
\[Online\]. Available:
#link("https://blog.mozilla.org/security/2021/08/10/firefox-91-introduces-enhanced-cookie-protection/")
. Accessed: Jul. 2026.

\[20\] J. Ravichandran, W. T. Na, J. Lang, and M. Yan, "PACMAN:
Attacking ARM Pointer Authentication with Speculative Execution," in
#emph[Proc. 49th ACM/IEEE Int. Symp. Computer Architecture (ISCA)], New
York, NY, USA, 2022, pp. 685-698. \[Online\]. Available:
#link("https://pacmanattack.com/")

\[21\] Google, "Overview of Manifest V3," Chrome Developers. \[Online\].
Available:
#link("https://developer.chrome.com/docs/extensions/mv3/intro/") .
Accessed: Jul. 2026.

\[22\] Google, "Memory Safety," Android Open Source Project. \[Online\].
Available:
#link("https://source.android.com/docs/security/test/memory-safety") .
Accessed: Jul. 2026.

\[23\] Google Project Zero, "0-days In-the-Wild." \[Online\]. Available:
#link("https://googleprojectzero.github.io/0days-in-the-wild/") .
Accessed: Jul. 2026.

\[24\] Mozilla Wiki, "Security/Sandbox," Oct. 2024. \[Online\].
Available: #link("https://wiki.mozilla.org/Security/Sandbox") .
Accessed: Jul. 2026.

\[25\] r/firefox, "Firefox Sandbox Isolation Hits Level 9 – The Gap with
Chrome Has Closed," Reddit, Jan. 2026. \[Online\]. Available:
#link("https://old.reddit.com/r/firefox/comments/1qkqfcx/firefox_sandbox_isolation_hits_level_9_the_gap/")[https://old.reddit.com/r/firefox/comments/1qkqfcx/firefox\_sandbox\_isolation\_hits\_level\_9\_the\_gap/]
. Accessed: Jul. 2026.

\[26\] Mozilla, "Firefox for Android 152.0 Release Notes," Jul. 2026.
\[Online\]. Available:
https://www.mozilla.org/en-US/firefox/android/152.0/releasenotes/

\[27\] Bug 2011886 - Switch off isolated processes by default. Mozilla
Bugzilla. https://bugzilla.mozilla.org/show\_bug.cgi?id\=2011886

\[28\] Bug 2011319 - Firefox for Android frequently and randomly going
back to the previous page. Mozilla Bugzilla.
https://bugzilla.mozilla.org/show\_bug.cgi?id\=2011319

\[29\] Bug 2012435 - Content process crashes when isolating a site with
Fission. Mozilla Bugzilla.
https://bugzilla.mozilla.org/show\_bug.cgi?id\=2012435

\[30\] Bug 2003658 - Make Fission + SHIP default in 147. Mozilla
Bugzilla. https://bugzilla.mozilla.org/show\_bug.cgi?id\=2003658

#line()
