# joostoostdijk.com

Personal blog built with [Jekyll](https://jekyllrb.com/) and the [Minimal Mistakes](https://mmistakes.github.io/minimal-mistakes/) theme, hosted on [GitHub Pages](https://pages.github.com/).

## Stack

- Static site: Jekyll + Minimal Mistakes theme
- Hosting: GitHub Pages
- Domain: managed via GoDaddy
- CDN / SSL: Cloudflare (free plan)

## Local development

Requires [mise](https://mise.jdx.dev/) for Ruby version management.

```sh
mise install        # install Ruby 3.3.11
bundle install      # install gems

just develop        # serve with drafts at http://localhost:4000
just qa             # serve without drafts
just deploy         # build + push to main
```
