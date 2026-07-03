# Draft: Mozilla Connect Discussion

**Platform:** connect.mozilla.org
**Category:** Firefox for Android / Security

---

## Title: GrapheneOS Advises Against Firefox on Android. Can Mozilla Address These Claims Publicly?

**Body:**

GrapheneOS, the hardening-focused Android OS, advises users against installing Firefox. Their official usage guide makes several specific security claims about GeckoView [1]:

1. "Firefox does not have internal sandboxing on Android"
2. Gecko-based browsers are "much more vulnerable to exploitation"
3. Firefox "bypass or cripple a fair bit of the upstream and GrapheneOS hardening work"
4. Extension-based privacy protections are "privacy theater"

I researched these claims and published a comparative analysis [2] that maps each one against current evidence. Some claims remain substantiated. Others appear partially or fully outdated as of 2026.

**What I found that may interest Mozilla engineers:**

- Firefox 147 (January 2026) shipped Site Isolation (Fission) for Android with release notes citing "the same Site Isolation safeguards already in use by desktop Firefox." This directly addresses GrapheneOS's claim about no internal sandboxing on Android. The implementation details on how Fission works at the kernel level on Android (given that unprivileged user namespaces are not available to apps) would be valuable to document publicly.

- Firefox's Rust migration (Stylo, RLBox, Necko, WebRender) is structurally significant for vulnerability resistance. But I want to be precise about its scope: Rust does not protect JIT-compiled SpiderMonkey code, logic bugs, or cryptographic side channels. It is one layer among several, not a panacea.

- Mozilla's 2025 collaboration with Anthropic's red team [3] and analysis of AI-discovered vulnerabilities [4] demonstrate ongoing investment in hardening. I note in my paper that Google applies comparable AI-assisted techniques, so this is not a unique Mozilla advantage, but it is real progress.

- The dual-engine attack surface concern (Firefox requires Chromium-based WebView on Android) describes a platform architectural constraint, not a Firefox deficiency. GrapheneOS could resolve this by substituting a GeckoView-based WebView for Vanadium, but chooses not to.

**Questions I could not answer from public documentation:**

1. Fission shipped on Android in Firefox 147. The release notes say "the same Site Isolation safeguards already in use by desktop Firefox." Community members noted that unprivileged user namespaces are not available on Android. What kernel-level mechanisms does Fission actually use on Android? How does the implementation differ from desktop?

2. GrapheneOS correctly notes that GeckoView does not use the `android:isolatedProcess` manifest attribute for child processes. Are there plans to adopt it, or is Mozilla pursuing a different kernel sandboxing strategy that achieves equivalent post-exploit containment?

3. Does Mozilla have internal metrics comparing severity-critical vulnerability density in Rust components versus C++ code paths? The 70% memory-safety statistic from Chromium's data is often cited, but similar data from Mozilla's own CVE triage would strengthen the evidence base.

4. Has the desktop Linux sandbox gap with Chromium narrowed since Fission's 2021 desktop release? GrapheneOS still characterizes Firefox's desktop sandbox as "substantially weaker," but the claim may be outdated.

**Why this matters:**

GrapheneOS's advisory is influential in the privacy and security community. If Mozilla has engineering responses to these claims, a public technical discussion would help users make informed decisions. Security practitioners who want to recommend Firefox on Android currently have no Mozilla-published rebuttal to cite.

I welcome any corrections to my analysis. The paper is CC BY 4.0 and I would be happy to update it with engineer feedback.

**References:**

[1] GrapheneOS, "Usage: Web Browsing." https://grapheneos.org/usage#web-browsing

[2] Full paper (HTML): https://YOUR-USER.github.io/YOUR-REPO/blog.html
    Full paper (PDF): https://YOUR-USER.github.io/YOUR-REPO/sandboxing-mitigation-comparative-analysis.pdf

[3] Mozilla, "Hardening Firefox Together with Anthropic's Red Team." https://blog.mozilla.org/en/firefox/hardening-firefox-anthropic-red-team/

[4] Mozilla, "AI Security and Zero-Day Vulnerabilities." https://blog.mozilla.org/en/privacy-security/ai-security-zero-day-vulnerabilities/

---

## Notes before posting

- **Fill in the links** to your HTML and PDF before posting.
- **Keep the tone collaborative**, not adversarial. The goal is to get engineers to engage, not to put them on the defensive.
- **Mozilla Connect** is read by product managers and engineers, but you may not get the same depth of technical response as on Discourse or GitHub. If this does not get traction within a week, cross-post to discourse.mozilla.org (Security category) with the same text.
- **Tag it appropriately.** Mozilla Connect lets you tag posts. Use "Firefox for Android" and "Security."
