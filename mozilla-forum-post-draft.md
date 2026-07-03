# Draft: Mozilla Discourse Post

**Target:** discourse.mozilla.org. Category: "Firefox" or "Security"

---

## Title: Seeking Technical Clarification on GeckoView Android Sandboxing Architecture

**Body:**

I'm an independent security researcher working on a comparative analysis of mobile browser security architectures. My paper evaluates the claims made by GrapheneOS regarding Gecko-based browsers on Android, and I'd like to verify my understanding of the current state of Firefox's Android security architecture. I would appreciate any corrections or clarifications from Mozilla engineers.

### Context

GrapheneOS's official usage guide [1] makes several claims about Firefox on Android:

1. "Firefox does not have internal sandboxing on Android"
2. Gecko-based browsers are "much more vulnerable to exploitation"
3. "Even in the desktop version, Firefox's sandbox is still substantially weaker (especially on Linux) and lacks full support for isolating sites"
4. Extension-based privacy/security is "privacy theater"

My research has found that several of these claims may be outdated as of early 2026, particularly given:

- **Firefox 147 (January 2026)** shipped Site Isolation (Fission) for Android with "the same Site Isolation safeguards already in use by desktop Firefox" [2]
- Firefox's extensive Rust adoption (Stylo, RLBox, Necko, WebRender) provides memory-safety guarantees that Chromium's predominantly C++ codebase does not match
- Mozilla's AI-assisted hardening collaboration with Anthropic's red team identified and fixed latent security bugs across the codebase
- Structural privacy features (Total Cookie Protection, Enhanced Tracking Protection, Containers) are enabled by default

### Specific Questions

**Q1: Fission on Android. Kernel-level differences from desktop.**

The Firefox 147 release notes state that Site Isolation uses "the same Site Isolation safeguards already in use by desktop Firefox." A PrivacyGuides community member noted that "unprivileged user namespaces are not available to apps on Android." Could a Mozilla engineer clarify:

- What kernel-level isolation mechanisms are used for Fission on Android versus desktop?
- How does the Android implementation compare architecturally to Chromium's strict site isolation on the same platform?
- Is there or will there be a published architecture document for Android Fission comparable to what was published for desktop?

**Q2: `android:isolatedProcess` sandboxing.**

GrapheneOS emphasizes that GeckoView does not use Android's `android:isolatedProcess="true"` manifest attribute for child processes. My understanding is that this remains accurate. Are there any plans or ongoing work to adopt `isolatedProcess` for GeckoView's content processes, or is Mozilla pursuing a different approach to kernel-level sandboxing?

**Q3: Desktop sandbox improvements.**

The GrapheneOS advisory claims that Firefox's desktop sandbox (particularly on Linux) is "substantially weaker" than Chromium's. Has this gap been narrowed since Fission shipped in Firefox 95 (December 2021)? Are there recent improvements that would warrant an updated comparison?

**Q4: Rust memory safety in the exploit calculus.**

My paper argues that Firefox's extensive Rust adoption reduces the probability of initial renderer compromise, which partially offsets the weaker post-compromise sandboxing. I also discuss the limitations of Rust-based guarantees: JIT-compiled SpiderMonkey code is outside Rust's safety scope, logic bugs are not prevented, and side-channel resistance is language-independent. Is there internal or published data Mozilla can share about the proportion of severity-critical vulnerabilities found in Rust versus C++ components?

### My Paper

The full paper is available at: [LINK TO PAPER once published]

It evaluates each GrapheneOS claim against current evidence, distinguishing between claims that remain substantiated, those that have been superseded, and those that reflect philosophical disagreements about threat modeling. I have tried to be scrupulously fair. I explicitly note where GrapheneOS's criticisms remain valid (the absence of `isolatedProcess`, the dual-engine requirement on Android).

I would welcome any technical corrections or clarifications from Mozilla engineers before I finalize the document for distribution. My goal is to produce an accurate, evidence-based assessment that the security community can rely on.

Thank you for your time and expertise.

### References

[1] GrapheneOS, "Usage: Web Browsing." https://grapheneos.org/usage#web-browsing

[2] Mozilla, "Firefox for Android 147.0 Release Notes," January 2026. https://www.mozilla.org/en-US/firefox/android/147.0/releasenotes/

---

## Alternative Shorter Version (for Reddit r/firefox)

**Title:** Seeking Mozilla engineer input on GeckoView security architecture for research paper

**Body:**

I'm writing a comparative analysis of mobile browser security (Firefox/GeckoView versus Chromium/Vanadium) and critically evaluating GrapheneOS's claims about Firefox on Android. I have a few technical questions I'm hoping Mozilla engineers can weigh in on:

1. **Fission on Android.** Firefox 147 shipped Site Isolation for Android. How does the kernel-level implementation differ from desktop, given that unprivileged user namespaces are not available to Android apps?

2. **`isolatedProcess`.** GrapheneOS correctly notes that GeckoView does not use `android:isolatedProcess`. Are there plans to adopt it, or is Mozilla pursuing a different kernel sandboxing strategy?

3. **Desktop sandbox.** Has the desktop Linux sandbox gap with Chromium narrowed since Fission shipped in 2021?

4. **Rust vs. C++ vulnerability data.** Does Mozilla have internal metrics on what proportion of critical-severity bugs are found in Rust versus C++ code paths?

If any Mozilla engineer has time to provide technical context, I would love to cite you in the paper. I have tried to be fair to both sides. My paper acknowledges where GrapheneOS's criticisms remain valid while identifying claims that appear outdated.

Paper draft available on request. Thanks!
