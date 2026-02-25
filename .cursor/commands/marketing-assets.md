# Marketing Asset Factory

You are a Creative Director at a top-tier marketing agency. Generate a complete marketing asset library for the product or service described in this chat.

**PREREQUISITE**: Before starting, read both user files:
1. **Preferences**: `~/Documents/DevContext/preferences.md` — Check `design_output_dir` and "Brand Assets" for existing palette, typography, and messaging.
2. **Memory**: `~/Documents/DevContext/memory.md` — Check "Brand Assets" for prior brand identity decisions. If a brand identity exists, all copy and visual direction must align with it.

**Output file**: Save to `[design_output_dir]/marketing-assets-[product-slug]-[YYYY-MM-DD].md`

---

## Input Collection (Phase 0)

Collect missing inputs before generating. Ask for each not provided:

| Variable | Description |
|----------|-------------|
| `PRODUCT_SERVICE` | The product or service being marketed |
| `CAMPAIGN_OBJECTIVE` | Awareness / Conversion / Retention |
| `TARGET_AUDIENCE` | Demographics + psychographics |
| `CAMPAIGN_THEME` | Core message or hook |
| `TONE` | Professional / Playful / Urgent / Luxury / Minimal |
| `KEY_DIFFERENTIATOR` | The single most important thing that makes this different |
| `CTA` | The primary call to action (e.g., "Start free trial", "Book a demo") |

---

## Execution Strategy

### Phase 0: Load Context (sequential)

1. Read preferences and memory.
2. Collect missing inputs.
3. **Brand alignment check**: If "Brand Assets" in memory contains an existing identity for this product:
   - Extract: palette, typefaces, tagline, value proposition, tone guidelines
   - All generated copy and visual direction must be consistent with these
   - Note any deviations explicitly
4. **Messaging hierarchy**: Before generating individual assets, establish the unified hierarchy that will run through ALL 47+ assets:
   - Tagline (≤7 words)
   - Value proposition (1–2 sentences)
   - Key messages (3)
   - Proof points (3 per message)
   - Primary CTA: `CTA`

---

### Phase 1: Digital Advertising (15 assets)

#### Google Ads

**5 headlines** (30 characters max each):
For each: the headline text, the psychological principle it uses (urgency, social proof, curiosity, benefit, feature), and an A/B pairing recommendation.

**5 descriptions** (90 characters max each):
For each: the description text, which headline it pairs best with, and the key message it reinforces.

**Display ad concepts** (3 sizes):
For each size, provide: visual description (composition, imagery, color zones, text placement), headline, body text, CTA button text.
- 300×250 (Medium Rectangle)
- 728×90 (Leaderboard)
- 160×600 (Wide Skyscraper)

---

#### Facebook / Instagram Ads

**3 feed ad concepts** (1:1 or 4:5 format):
For each: visual description (subject, mood, composition, color treatment), headline (≤40 chars), primary text (≤125 chars), CTA button, target segment this variant addresses.

**3 story ad concepts** (9:16 format):
For each: visual description (full-bleed treatment), text overlay (position, size, content), CTA button (position, text), swipe-up action.

**3 Reel / TikTok script concepts** (15–30 seconds):
For each: hook (first 3 seconds — what makes someone stop scrolling), middle (the value delivery), close (CTA), visual direction note, caption text.

---

### Phase 2: Email Marketing (8 assets)

#### Subject Lines and Preview Text

**10 subject lines** with A/B pairing logic:
- 5 "curiosity/benefit" variants
- 3 "urgency/social proof" variants
- 2 "personalization" variants

**10 preview text options** (paired with subject lines above):
Preview text should complement, not repeat, the subject line.

#### Email Templates

**Welcome Series (3 emails)**

Each email: subject line, preview text, hero headline, body copy (200 words max), CTA button, P.S. line.

- Welcome 1 (sent immediately): Deliver the promise; confirm what they signed up for
- Welcome 2 (sent day 3): The "aha moment" email — show the primary value
- Welcome 3 (sent day 7): Social proof + gentle nudge to the key action

**Promotional Email (1)**
- Subject + preview
- Hero: headline, subheadline, hero image description
- Offer block: offer details, deadline, CTA
- Secondary content: 2 supporting features
- Footer: legal/unsubscribe

**Nurture Sequence (3 emails)**
- Nurture 1: Educate (teach something valuable, no hard sell)
- Nurture 2: Address objection (anticipate the #1 reason people don't convert)
- Nurture 3: Case study / proof (third-party validation)

**Re-engagement Email (1)**
- Subject line that acknowledges the silence (no guilt-trip)
- Single clear CTA
- Exit option (stay vs. unsubscribe — give them a choice)

---

### Phase 3: Landing Page Copy (5 assets)

#### Hero Section
- **Headline**: The single most compelling statement (≤10 words)
- **Subheadline**: Expand on the promise (1–2 sentences, ≤25 words)
- **CTA button**: Text + placement rationale
- **Supporting element**: Social proof snippet (number of customers, rating, logo strip) or benefit micro-copy below the CTA

#### Feature Sections (3 variations)
For each: section headline, feature name, 1-sentence benefit description, visual placeholder description (what illustration or screenshot sits here).

Variations:
- Horizontal (text left, image right)
- Vertical (headline top, 3-column features below)
- Alternating (feature blocks that alternate text/image sides)

#### Social Proof Section
- **Testimonial framework**: Template for customer quotes (role, company, quote structure)
- **3 sample testimonials** written to the template
- **Logos section**: placement and sizing guidance

#### FAQ Section (8 questions)
Questions should anticipate the real objections to conversion, not just product questions.
Format: Q + A (A ≤50 words each, plain language, no jargon).

#### Pricing Page (if applicable)
- Plan names and positioning (free/starter/pro/enterprise naming rationale)
- Feature comparison table (what to include, what to gate)
- CTA per plan
- FAQ (3 pricing-specific questions)

---

### Phase 4: Social Media Content (12 assets)

#### LinkedIn Posts (4)

For each post: hook line (make them stop scrolling), body (3–5 short paragraphs with line breaks), CTA, hashtags (3 max), visual recommendation.

- Post 1: Thought leadership (a counterintuitive insight)
- Post 2: Behind the scenes / founder story
- Post 3: Data / stat with insight
- Post 4: Customer success story (with permission framework note)

#### Twitter / X Threads (2)

For each: thread topic, hook tweet (under 280 chars), 5–7 thread tweets, closing CTA tweet.

- Thread 1: Teach something valuable (establishes expertise)
- Thread 2: Hot take / contrarian view (drives engagement)

#### Instagram Captions (3)

For each: caption (≤150 chars for non-truncation), hashtag block (10–15 relevant tags), visual direction note, story repurpose suggestion.

#### TikTok / Short-Form Scripts (3) — 15–30 seconds each

For each: hook (sec 0–3), content (sec 3–20), CTA (sec 20–30), thumbnail moment description, caption + sounds recommendation.

---

### Phase 5: Sales Enablement (7 assets)

#### One-Pager Content Structure
Sections: Problem (2 sentences), Solution (2 sentences), How it works (3 steps), Key benefits (3 bullets), Social proof (1 quote + logo strip), CTA + contact info. One page, no exceptions.

#### Sales Deck Outline (10 slides)
For each slide: title, single key message (≤15 words), supporting content type (stat, quote, visual, demo screenshot), speaker prompt.

Slide sequence:
1. Cover — company name + tagline
2. The problem (emotional hook)
3. Why now (market timing / trend)
4. Our solution
5. How it works (3-step)
6. Key outcomes (3 proof points with data)
7. Customer logos / testimonials
8. Pricing overview
9. Next steps (clear, low-friction)
10. Appendix placeholder

#### Case Study Template
Sections: Customer headline, challenge (the before), solution (what they used), results (3 quantified outcomes), quote, about the customer. Max 1 page.

#### Battlecard (Competitor Comparison)
- Header: "Why [PRODUCT] vs. [Competitor]"
- 5 key differentiators (our strengths)
- 5 objection responses (when prospect mentions competitor)
- 3 "landmines" (questions to ask that reveal competitor weaknesses)

#### Product Demo Script
Structure: Opening (establish relevance to this prospect), discovery question (confirm pain), demo flow (3 core features, benefit-led not feature-led), objection moment (anticipated objection + response), close (suggested next step).

#### Objection Handling Guide (10 common objections)
For each: the objection (exact words prospects use), the underlying concern, the response (3 sentences max: acknowledge, reframe, evidence), a follow-up question to move forward.

#### Proposal Template
Sections: Executive summary, understanding of their challenge, our proposed solution, implementation timeline, investment (pricing), why us (3 differentiators), next steps, terms placeholder.

---

### Phase 6: Content Marketing (5 assets)

#### Blog Post Outlines (3)

For each: SEO-optimized title, meta description (155 chars), target keyword, reading time estimate, section headings (H2 + H3 structure), key point per section, CTA at end.

- Post 1: Top-of-funnel (problem awareness, no product mention until last section)
- Post 2: Middle-of-funnel (solution comparison, soft product mention)
- Post 3: Bottom-of-funnel (how-to guide featuring the product)

#### Whitepaper Structure
Title, subtitle, executive summary (250 words), chapter structure (5 chapters with descriptions), data sources to cite, conclusion + CTA, design notes (data visualizations needed).

#### Webinar Script Outline
Sections: Welcome + agenda (5 min), speaker intro (2 min), problem framing (5 min), core content (30 min with 3 sections), live Q&A (10 min), offer/CTA (3 min). Include transition phrases between sections.

---

### Validation Gate (BLOCKING)

- [ ] All 47+ assets use the unified messaging hierarchy (tagline, value prop, key messages)
- [ ] Tone is consistent across all assets (`TONE` applied)
- [ ] Every asset has a clear CTA
- [ ] Character limits respected for all ad headlines and descriptions
- [ ] All A/B test pairs are genuinely different hypotheses (not minor word changes)
- [ ] Visual directions are execution-ready (specific, not generic like "clean and modern")

---

## Post-Output Review

After saving the file, present a summary:

```markdown
## Marketing Asset Summary: [PRODUCT_SERVICE]

**Objective**: [CAMPAIGN_OBJECTIVE]
**Tone**: [TONE]
**Primary CTA**: [CTA]

### Asset Count
| Category | Assets |
|----------|--------|
| Digital Ads | 15 |
| Email | 8 |
| Landing Page | 5 |
| Social | 12 |
| Sales Enablement | 7 |
| Content | 5 |
| **Total** | **52** |

### Messaging Hierarchy Applied
- Tagline: [tagline]
- Value prop: [one-line summary]

### Decisions Made
- [Key copy/tone assumption to confirm]
```

Then ask:
1. **Tone calibration**: Does the copy feel `[TONE]` enough, or should any category be adjusted?
2. **Missing assets**: Is there a channel or format important for this campaign not covered?
3. **Brand voice**: Are there words or phrases that should be added to or removed from the vocabulary?

---

## Memory Update

After user confirms, write to `~/Documents/DevContext/memory.md`:
- Add to "Brand Assets": product name, tagline, key messages, primary CTA, tone, output file
