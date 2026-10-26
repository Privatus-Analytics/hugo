# Privatus Analytics for Hugo

**See how many people visit your Hugo site, which pages they read and where
they came from. No cookies, honest numbers, and a dashboard you understand in
seconds.**

## The problem

You built a site with Hugo and want to know if anyone reads it. Most
analytics tools make that hard. Google Analytics is slow, confusing and sends
what your visitors do to Google. In many countries it also means showing a
cookie pop-up (the box that asks visitors to accept cookies). Many people
click "reject", so you never see them. Bots fill up the numbers that are left.

## The solution

Privatus Analytics counts visits without cookies and never stores IP
addresses. Bots are filtered out before they are counted. This Hugo module
adds the small Privatus Analytics script to your pages from one line in your
config. Your own visits while you write with `hugo server` are not counted.

## What you get

- **A dashboard you understand in seconds.** Visitors, top pages and where
  people came from, all on one screen.
- **No cookie pop-up needed for our analytics.** We set no cookies and store
  no personal data. Laws differ by country, so check your own legal advice.
- **Honest numbers.** Known bots and fake traffic are left out on every plan.
- **A fast site.** The tracking script is about 3 KB and loads after your page.
- **Clicks you care about.** A shortcode turns any link into a tracked event,
  like "Signup clicked".
- **Data you own.** We never sell it or show you ads, and you can pull it out
  any time through the API.

**Start free.** The Free plan has 10,000 events a month and 3 sites, with no
card. Every new account also gets 14 days of Pro free, with no card.
[Create your account](https://privatusanalytics.com).

## Requirements

- Hugo 0.136.0 or later. Tested with 0.136.0 and 0.167.0.
- Go, because Hugo uses it to download modules. You only need it on the
  computer that builds the site.
- A Privatus Analytics site id. It starts with `pa_`. You find it in Privatus
  Analytics under Site settings, Tracking.

## Install

If your site is not a Hugo module yet, turn it into one first (use your own
name in place of the GitHub path):

```sh
hugo mod init github.com/you/your-site
```

Then get this module:

```sh
hugo mod get github.com/Privatus-Analytics/hugo@v1.0.0
```

and add it to your config, with your site id.

`hugo.toml`:

```toml
[module]
  [[module.imports]]
    path = "github.com/Privatus-Analytics/hugo"

[params.privatusAnalytics]
  siteId = "pa_YOURSITEID"
```

`hugo.yaml`:

```yaml
module:
  imports:
    - path: github.com/Privatus-Analytics/hugo

params:
  privatusAnalytics:
    siteId: pa_YOURSITEID
```

If you already import a theme as a module, keep it and add this module to the
same list.

## Add the script to your pages

Put the partial in the `<head>` of your base layout. In most sites this is
`layouts/_default/baseof.html`, or a head partial of your theme that you copy
into your own `layouts` folder:

```go-html-template
<head>
  <title>{{ .Title }}</title>
  {{ partial "privatus-analytics.html" . }}
</head>
```

When you run `hugo` to build your site, every page gets:

```html
<script defer src="https://privatusstats.com/js/pa.js" data-site="pa_YOURSITEID"></script>
```

Nothing prints on `hugo server`, so your own visits while you write are never
counted. Nothing prints without a site id, or with a site id that does not
look like `pa_` followed by letters and digits.

## Settings

Every setting except `siteId` is optional.

`hugo.toml`:

```toml
[params.privatusAnalytics]
  siteId = "pa_YOURSITEID"
  modules = ["engage", "auto", "vitals", "clicks"]
  domains = ["example.com", "www.example.com"]
  exclude = ["/drafts/*", "/preview/*"]
  mask = "/users/*->/users/:id"
  spa = "auto"
  manual = false
  enableOnServer = false
  [params.privatusAnalytics.attributes]
    data-canonical = "true"
```

`hugo.yaml`:

```yaml
params:
  privatusAnalytics:
    siteId: pa_YOURSITEID
    modules: [engage, auto, vitals, clicks]
    domains: [example.com, www.example.com]
    exclude: [/drafts/*, /preview/*]
    mask: /users/*->/users/:id
    spa: auto
    manual: false
    enableOnServer: false
    attributes:
      data-canonical: "true"
```

| Setting | Script attribute | What it does |
|---|---|---|
| `siteId` | `data-site` | Your site id. Nothing prints without it |
| `modules` | `data-modules` | Extra tracker features. Setting it replaces the default (`engage`), so keep `engage` for time on page and scroll depth. An empty list loads none |
| `domains` | `data-domains` | Count only these hostnames, so copies and previews of your site are left out |
| `exclude` | `data-exclude` | Paths that are never counted. `*` matches anything |
| `mask` | `data-mask` | Rewrites paths before they are sent, like `/users/*->/users/:id` |
| `spa` | `data-spa` | How page changes without a reload are followed: `auto`, `history`, `hash` or `off` |
| `manual` | `data-manual` | `true` turns off the automatic page view |
| `enableOnServer` | | `true` prints the script on `hugo server` too |
| `attributes` | any `data-*` | Any other tracker attribute. Names that do not start with `data-` are left out |

Lists can also be written as one text with commas, like `"engage,auto"`.
Every attribute is explained in the [script attributes
reference](https://privatusanalytics.com/docs/tracker/attributes), and the
modules in [Modules](https://privatusanalytics.com/docs/tracker/modules).

### Set the site id on your build server

Hugo reads settings from environment variables too, so you can keep the site
id out of your config:

```sh
HUGO_PARAMS_PRIVATUSANALYTICS_SITEID=pa_YOURSITEID hugo
```

### Testing on hugo server

To see the script while you write, set `enableOnServer = true`. The tracker
ignores `localhost` unless you also add `data-debug = "true"` (it then shows
each hit in the browser console and sends nothing) or `data-allow-local =
"true"` under `attributes`. See [Debug
mode](https://privatusanalytics.com/docs/tracker/debug).

## Track clicks on a link

The `privatus-link` shortcode makes a link that sends a custom event when
someone clicks it. Use it in your Markdown pages:

```markdown
{{< privatus-link href="https://example.com/signup" event="Signup clicked" plan="pro" >}}Start free{{< /privatus-link >}}
```

It prints:

```html
<a href="https://example.com/signup" data-privatus-event="Signup clicked" data-privatus-prop-plan="pro">Start free</a>
```

- `href` and `event` are the link and the event name. The name is cut to 120
  characters.
- `target`, `rel`, `class`, `id` and `title` go on the link as they are. With
  `target="_blank"` and no `rel`, it adds `rel="noopener"`.
- `click` gives the link a name for [click
  maps](https://privatusanalytics.com/docs/features/click-maps), like
  `click="pricing.cta"`. It may use letters, digits and `_ . : -`.
- Every other parameter becomes an event property. Names are made lowercase,
  and anything that is not a letter, a digit or `_` becomes `_`. So
  `button-location="hero"` becomes the property `button_location`. At most 30.
- The link text may use Markdown, like `**bold**`.

Use a short "Noun verb" name, like `Signup clicked` or `Guide downloaded`, and
put details in properties. Then all clicks add up in one place and you can
split them by property. Never put names, emails or anything that points to one
person in properties.

The event is sent by the tracker in the browser, so it only works on pages
that have the script. With the `auto` module, links to other sites are counted
by themselves. A link made with this shortcode is counted once, as your named
event. See [HTML
attributes](https://privatusanalytics.com/docs/events/html-attributes) for how
it works.

## Privacy

This module only prints a script tag and HTML attributes. Your visitors'
browsers send the page views and events to Privatus Analytics. Nothing is sent
when you build your site. The script sets no cookies and stores nothing in the
browser. See the [privacy
documentation](https://privatusanalytics.com/docs/privacy) for what is
collected.

If you have a privacy policy, it should say which tools handle your visitors'
data. You can paste this:

> This website uses [Privatus Analytics](https://privatusanalytics.com/privacy-analytics)
> to count visits. It does not use cookies and does not follow you from one
> website to another. Your IP address is used for a moment to count visits and
> is never stored.

## Update

```sh
hugo mod get -u github.com/Privatus-Analytics/hugo
```

## Development

`exampleSite/` is a tiny site that uses the module from this folder.
`tests/run.sh` builds it with different settings and checks the output. Run
it in the same Hugo image as CI:

```sh
docker run --rm -e HUGO_CACHEDIR=/tmp/hugo_cache -v "$PWD:/project" \
  --entrypoint sh ghcr.io/gohugoio/hugo:v0.167.0 /project/tests/run.sh
```

## Contributing

Bug reports and pull requests are welcome at
https://github.com/Privatus-Analytics/hugo.

## License

MIT. See [LICENSE](LICENSE). Privatus Analytics is a product of Two Phase LLC,
Wyoming, USA.
