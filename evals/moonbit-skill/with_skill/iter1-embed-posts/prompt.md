# iter1 embed-posts (with_skill)

> go/examples/blog/posts/*.md を MoonBit から使えるように埋め込んで（記事のパスと本文の組として）。生成したソースはコミットしないこと。make build と wrangler dev の再ビルドでも反映されるようにして。

Base commit of the run's clone: `62c287d` (with the skill as of that commit)

**Note:** Stopped its server with `pkill -f workerd`; the user's own `wrangler dev` on 8787 stopped responding afterwards. It also edited its copy of the skill (included in the patch).
