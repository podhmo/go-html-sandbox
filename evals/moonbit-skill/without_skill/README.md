# moonbit skill evals: without_skill

Records of eval runs of `.claude/skills/moonbit`, kept for later review; not for merging.
Each directory has the prompt, the run's changes as a patch, its own summary, and the grading.

| Run | Grade | Time (s) | Tokens | Note |
|---|---|---|---|---|
| [iter1-compare-cli](iter1-compare-cli/) | 8/8 | 280.6 | 80831 | Contaminated: the skill's deletion was left unstaged in this clone, so `git diff` printed SKILL.md to the run. |
| [iter1-add-page](iter1-add-page/) | 8/8 | 59.8 | 28891 | Stopped its server with `pkill -f workerd`, which can kill other workerd processes. |
| [iter1-embed-posts](iter1-embed-posts/) | 8/9 | 258.4 | 61942 |  |
| [iter2-html-builder](iter2-html-builder/) | 8/9 | 185.0 | 55897 |  |
| [iter2-markdown](iter2-markdown/) | 9/9 | 261.0 | 86234 |  |
