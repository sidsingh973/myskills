---
name: verify-claim
description: Adversarial claim verification — try to REFUTE a claim, return verdict + evidence. Refute-by-default.
---

# /verify-claim — Adversarial Verification

Takes a claim and tries to refute it. Default stance: REFUTED unless evidence survives the attack.
This is the "every claim is receipted" reliability thesis in action.

## Usage

Researcher: for any claim you plan to report, run it through this protocol first.

```
CLAIM: <exact statement to verify>

TASK:
1. State your prior: does this seem plausible on its face? (1 sentence)
2. Try to REFUTE it. Look for:
   - Counter-evidence (sources that say the opposite)
   - Scope violations (true in one context, false in another)
   - Recency failures (was true, no longer is)
   - Measurement errors (the stat is real but means something different)
3. If you find a refutation: REFUTED — state what specifically breaks it + source.
4. If you cannot refute after genuine effort: SURVIVES — state what you tried + why it held.
5. Confidence: HIGH / MEDIUM / LOW

OUTPUT FORMAT:
Verdict: REFUTED | SURVIVES
What I tried: <methods used to refute>
Finding: <what broke it OR what held>
Confidence: HIGH | MEDIUM | LOW
Source: <T1 source or "no T1 source found">
```

## Tiers of evidence

- **T1** — primary source (paper, repo, official docs, direct measurement)
- **T2** — secondary source (article citing T1, reputable journalist)
- **T3** — inference / training data / agent memory — flag explicitly, never pass as T1

## Rules

- **Refute-by-default.** If you can't find T1 evidence that the claim holds, verdict = REFUTED.
- **"Couldn't find counter-evidence" ≠ SURVIVES.** You must find positive evidence.
- **No self-certification.** The agent that made the claim does not run this protocol on their own claim.
