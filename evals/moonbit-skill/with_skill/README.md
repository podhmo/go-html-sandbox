# moonbit skill evals: with_skill

Records of eval runs of `.claude/skills/moonbit`, kept for later review; not for merging.
Each directory has the prompt, the run's changes as a patch, its own summary, and the grading.

| Run | Grade | Time (s) | Tokens | Note |
|---|---|---|---|---|
| [iter1-compare-cli](iter1-compare-cli/) | 8/8 | 386.7 | 97816 |  |
| [iter1-add-page](iter1-add-page/) | 8/8 | 75.2 | 34273 |  |
| [iter1-embed-posts](iter1-embed-posts/) | 8/9 | 332.2 | 78584 | Stopped its server with `pkill -f workerd`; the user's own `wrangler dev` on 8787 stopped responding afterwards. It also edited its copy of the skill (included in the patch). |
| [iter2-html-builder](iter2-html-builder/) | 8/9 | 247.1 | 79956 |  |
| [iter2-markdown](iter2-markdown/) | 9/9 | 269.2 | 90900 |  |
