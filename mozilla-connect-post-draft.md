# Mozilla Connect Discussion Post (Ready to Publish)

**Title:** GrapheneOS Advises Against Firefox on Android -- Can Mozilla Address These Claims?

**Category:** Firefox for Android
**Tags:** Security

---

GrapheneOS, the hardening-focused Android OS, advises users against installing Firefox. Their official usage guide makes several specific security claims about GeckoView [1]:

1. "Firefox does not have internal sandboxing on Android"
2. Gecko-based browsers are "much more vulnerable to exploitation"
3. Firefox "bypass or cripple a fair bit of the upstream and GrapheneOS hardening work"
4. Extension-based privacy protections are "privacy theater"

I researched these claims and published a comparative analysis [2] that maps each one against current evidence as of July 2026 (Firefox 152). Some claims remain substantiated. Others are partially or fully outdated.

**What I found that may interest Mozilla engineers:**

**Site Isolation (Fission) on Android.** Firefox 147.0 (January 2026) shipped Fission with release notes citing Spectre-class side-channel protection [12]. However, Firefox 147.0.2 (February 2026) disabled Fission on release and beta channels due to content process crashes causing random back-navigation (Bug 2011319). The isolation strategy default was reverted to ISOLATE_NOTHING for release and beta; only nightly and developer channels retained ISOLATE_HIGH_VALUE [27].

As of Firefox 152 (July 2026), Fission remains disabled on release and beta channels. Bug 2012435 (content process crashes when isolating sites) is still open [29]. The Nimbus experiment configuration confirms this: `isolationStrategy: 0` (ISOLATE_NOTHING) for release and beta, `isolationStrategy: 2` (ISOLATE_HIGH_VALUE) for nightly and developer.

This is the single most significant gap that GrapheneOS and security-conscious users point to. If Mozilla could provide a status update on Bug 2012435, it would substantially change the community's security assessment.

**Specific questions I could not answer from public documentation:**

1. **Fission re-enablement timeline.** What is the current plan for re-enabling Fission on release channels? Bug 2012435 has been open since February 2026 and is still unresolved as of July 2026. Is there an ETA for the fix?

2. **Release note transparency.** The Fission rollback in 147.0.2 was not mentioned in the release notes. Users discovered it through Bugzilla. Will future security-relevant configuration changes be disclosed in release notes?

3. **Kernel-level isolation mechanism.** Community members noted that unprivileged user namespaces are not available on Android. What kernel-level mechanisms does Fission actually use on Android, and is `isolatedProcess` adoption on the roadmap?

4. **Rust vs. C++ vulnerability metrics.** Does Mozilla have internal data comparing severity-critical vulnerability density in Rust components versus C++ code paths? The 70% memory-safety statistic from Chromium is often cited. Similar data from Mozilla's own CVE triage would strengthen the evidence base.

5. **Desktop Linux sandbox.** Mozilla's Windows sandbox has reached Level 9 (Win32k lockdown), matching Chromium's capabilities. Has the desktop Linux sandbox gap narrowed since the original GrapheneOS assessment?

**Why this matters:**

GrapheneOS's advisory is influential in the privacy and security community. If Mozilla has engineering responses to these claims, a public technical discussion would help users make informed decisions. Security practitioners who want to recommend Firefox on Android currently have no Mozilla-published rebuttal to cite.

I am not asking Mozilla to prioritize Fission over other security work. I am asking for transparency about the current state so that the community can make accurate threat-model assessments. A public status update would be valuable even without a firm ETA.

I welcome any corrections to my analysis. The paper is CC BY 4.0 and I would be happy to update it with engineer feedback.

**References:**

[1] GrapheneOS, "Usage: Web Browsing." https://grapheneos.org/usage#web-browsing

[2] Full paper (HTML): https://spiritofstar.github.io/blog.html
    Full paper (PDF): https://spiritofstar.github.io/sandboxing-mitigation-comparative-analysis.pdf

[3] Mozilla, "Hardening Firefox Together with Anthropic's Red Team." https://blog.mozilla.org/en/firefox/hardening-firefox-anthropic-red-team/

[4] Mozilla, "AI Security and Zero-Day Vulnerabilities." https://blog.mozilla.org/en/privacy-security/ai-security-zero-day-vulnerabilities/

[12] Firefox 147 Release Notes: https://www.mozilla.org/en-US/firefox/android/147.0/releasenotes/

[27] Bug 2011886 - Switch off isolated processes by default: https://bugzilla.mozilla.org/show_bug.cgi?id=2011886

[28] Bug 2011319 - Random back-navigation: https://bugzilla.mozilla.org/show_bug.cgi?id=2011319

[29] Bug 2012435 - Content process crashes when isolating sites: https://bugzilla.mozilla.org/show_bug.cgi?id=2012435

[30] Bug 2003658 - Make Fission + SHIP default in 147: https://bugzilla.mozilla.org/show_bug.cgi?id=2003658

---

**Posting checklist:**
- [ ] Copy this body (not the checklist) into Mozilla Connect
- [ ] Set category to "Firefox for Android"
- [ ] Add tags: "Security", "Firefox for Android"
- [ ] If no response within a week, cross-post to discourse.mozilla.org (Security category)
