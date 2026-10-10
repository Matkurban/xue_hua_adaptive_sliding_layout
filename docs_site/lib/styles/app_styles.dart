import 'tokens.dart';

/// Global stylesheet.
///
/// Theming is done with CSS custom properties: `:root` holds light values,
/// dark values apply when `html[data-theme="dark"]` is set **or** when no
/// explicit choice exists and the OS prefers dark. This makes "follow the
/// system" work with zero JavaScript and keeps SSR output theme-agnostic.
const String _light = '''
  --bg: #ffffff; --bg-soft: #f6f8fa; --bg-elev: #ffffff; --fg: #1f2328; --fg-muted: #59636e;
  --border: #d1d9e0; --accent: #0b6bcb; --accent-soft: rgba(11,107,203,.10); --accent-fg: #ffffff;
  --code-bg: #f6f8fa; --code-fg: #1f2328;
  --tok-comment: #6e7781; --tok-string: #0a7d3b; --tok-keyword: #cf222e; --tok-type: #8250df;
  --tok-number: #0550ae; --tok-annotation: #953800; --tok-key: #0550ae; --tok-punct: #57606a;
  --info: #0969da; --tip: #1a7f37; --warning: #9a6700; --danger: #cf222e;
  --shadow: 0 1px 3px rgba(31,35,40,.08), 0 8px 24px rgba(31,35,40,.06);
''';

const String _dark = '''
  --bg: #0d1117; --bg-soft: #151b23; --bg-elev: #161b22; --fg: #e6edf3; --fg-muted: #9198a1;
  --border: #30363d; --accent: #4493f8; --accent-soft: rgba(68,147,248,.15); --accent-fg: #0d1117;
  --code-bg: #151b23; --code-fg: #e6edf3;
  --tok-comment: #8b949e; --tok-string: #7ee787; --tok-keyword: #ff7b72; --tok-type: #d2a8ff;
  --tok-number: #79c0ff; --tok-annotation: #ffa657; --tok-key: #79c0ff; --tok-punct: #8b949e;
  --info: #4493f8; --tip: #3fb950; --warning: #d29922; --danger: #f85149;
  --shadow: 0 1px 3px rgba(0,0,0,.4), 0 8px 24px rgba(0,0,0,.3);
''';

final String appCss =
    '''
:root { $_light color-scheme: light; }
:root[data-theme="dark"] { $_dark color-scheme: dark; }
@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) { $_dark color-scheme: dark; } }

*, *::before, *::after { box-sizing: border-box; }
html { scroll-behavior: smooth; scroll-padding-top: ${Layout.headerHeight + 16}px; -webkit-text-size-adjust: 100%; }
@media (prefers-reduced-motion: reduce) { html { scroll-behavior: auto; } *, *::before, *::after { transition: none !important; animation: none !important; } }
body { margin: 0; background: var(--bg); color: var(--fg); line-height: 1.65;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", Roboto, sans-serif;
  transition: background-color .2s, color .2s; }
a { color: var(--accent); text-decoration: none; }
a:hover { text-decoration: underline; }
button { font: inherit; color: inherit; }
:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; border-radius: 4px; }

.skip-link { position: absolute; left: -999px; top: 8px; z-index: 100; padding: 8px 12px; background: var(--accent); color: var(--accent-fg); border-radius: 6px; }
.skip-link:focus { left: 8px; }
.site { min-height: 100vh; display: flex; flex-direction: column; }
.site__main { flex: 1; }
.container { width: 100%; margin: 0 auto; padding: 0 clamp(16px, 3vw, 32px); }
.container--wide { max-width: 1440px; }
.container--content { max-width: ${Layout.contentMax}px; }

/* Header */
.site-header { position: sticky; top: 0; z-index: 40; height: ${Layout.headerHeight}px; border-bottom: 1px solid var(--border);
  background: color-mix(in srgb, var(--bg) 85%, transparent); backdrop-filter: saturate(180%) blur(12px); }
.site-header__inner { height: 100%; display: flex; align-items: center; gap: 16px; }
.brand { display: flex; align-items: center; gap: 8px; color: var(--fg); font-weight: 700; white-space: nowrap; }
.brand:hover { text-decoration: none; }
.brand__logo { width: 24px; height: 24px; display: block; }
.site-header__nav { display: flex; gap: 4px; margin-left: 16px; }
.site-header__nav a { padding: 6px 10px; border-radius: 6px; color: var(--fg-muted); font-size: 14px; font-weight: 500; }
.site-header__nav a:hover, .site-header__nav a.is-active { color: var(--fg); background: var(--bg-soft); text-decoration: none; }
.site-header__actions { margin-left: auto; display: flex; align-items: center; gap: 8px; }
.icon-button { display: inline-flex; align-items: center; justify-content: center; width: 36px; height: 36px; border: 1px solid var(--border);
  border-radius: 8px; background: var(--bg-elev); cursor: pointer; transition: background-color .15s, border-color .15s; }
.icon-button:hover { background: var(--bg-soft); border-color: var(--accent); }
.site-header__menu { display: none; }
.segmented { display: inline-flex; padding: 2px; border: 1px solid var(--border); border-radius: 8px; background: var(--bg-soft); }
.segmented__item { border: 0; background: transparent; padding: 4px 10px; border-radius: 6px; font-size: 13px; cursor: pointer; color: var(--fg-muted); }
.segmented__item.is-active { background: var(--bg-elev); color: var(--fg); box-shadow: var(--shadow); }

/* Doc layout */
.doc-layout { max-width: 1440px; margin: 0 auto; display: grid; grid-template-columns: ${Layout.sidebarWidth}px minmax(0, 1fr) ${Layout.tocWidth}px; gap: 0 40px; padding: 0 clamp(16px, 3vw, 32px); }
.doc-layout__sidebar, .doc-layout__toc { position: sticky; top: ${Layout.headerHeight}px; align-self: start; max-height: calc(100vh - ${Layout.headerHeight}px); overflow-y: auto; padding: 24px 0; }
.doc-layout__content { min-width: 0; max-width: ${Layout.contentMax}px; padding: 32px 0 64px; }
.doc-layout__backdrop { display: none; }
@media (max-width: ${Breakpoints.toc - 1}px) { .doc-layout { grid-template-columns: ${Layout.sidebarWidth}px minmax(0, 1fr); } .doc-layout__toc { display: none; } }
@media (max-width: ${Breakpoints.drawer - 1}px) {
  .site-header__menu { display: inline-flex; }
  .site-header__nav, .brand__name { display: none; }
  .doc-layout { grid-template-columns: minmax(0, 1fr); }
  .doc-layout__sidebar { position: fixed; z-index: 60; top: ${Layout.headerHeight}px; bottom: 0; left: 0; width: min(85vw, ${Layout.sidebarWidth + 24}px);
    max-height: none; padding: 16px; background: var(--bg); border-right: 1px solid var(--border); transform: translateX(-100%);
    transition: transform .25s cubic-bezier(.2,.8,.2,1); visibility: hidden; }
  .is-drawer-open .doc-layout__sidebar { transform: none; visibility: visible; box-shadow: var(--shadow); }
  .doc-layout__backdrop { display: block; position: fixed; inset: ${Layout.headerHeight}px 0 0 0; z-index: 55; background: rgba(0,0,0,.4); opacity: 0; pointer-events: none; transition: opacity .25s; }
  .is-drawer-open .doc-layout__backdrop { opacity: 1; pointer-events: auto; }
}

/* Sidebar */
.sidebar__group { margin-bottom: 8px; }
.sidebar__group-toggle { width: 100%; display: flex; justify-content: space-between; align-items: center; border: 0; background: none; cursor: pointer;
  padding: 6px 8px; font-size: 12px; font-weight: 700; letter-spacing: .04em; text-transform: uppercase; color: var(--fg-muted); border-radius: 6px; }
.sidebar__group-toggle:hover { background: var(--bg-soft); }
.sidebar__chevron { transition: transform .2s; font-size: 16px; }
.sidebar__group.is-expanded .sidebar__chevron { transform: rotate(90deg); }
.sidebar__list { list-style: none; margin: 2px 0 0; padding: 0 0 0 8px; border-left: 1px solid var(--border); margin-left: 8px; display: none; }
.sidebar__group.is-expanded .sidebar__list { display: block; }
.sidebar__link { display: block; padding: 5px 12px; margin-left: -9px; border-left: 2px solid transparent; color: var(--fg-muted); font-size: 14px; }
.sidebar__link:hover { color: var(--fg); text-decoration: none; border-left-color: var(--border); }
.sidebar__link.is-active { color: var(--accent); font-weight: 600; border-left-color: var(--accent); background: var(--accent-soft); border-radius: 0 6px 6px 0; }

/* TOC */
.toc__title { margin: 0 0 8px; font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: .04em; color: var(--fg-muted); }
.toc ul { list-style: none; margin: 0; padding: 0; border-left: 1px solid var(--border); }
.toc__item a { display: block; padding: 3px 12px; font-size: 13px; color: var(--fg-muted); }
.toc__item a:hover { color: var(--accent); text-decoration: none; }
.toc__item--h3 a { padding-left: 24px; }

/* Article typography */
.doc-eyebrow { margin: 0; color: var(--accent); font-size: 13px; font-weight: 600; }
.doc-title { margin: 4px 0 8px; font-size: clamp(28px, 4vw, 36px); line-height: 1.2; letter-spacing: -.02em; }
.doc-lead { margin: 0 0 24px; font-size: 18px; color: var(--fg-muted); }
.prose h2 { margin: 40px 0 12px; padding-bottom: 6px; border-bottom: 1px solid var(--border); font-size: 24px; line-height: 1.3; }
.prose h3 { margin: 28px 0 8px; font-size: 19px; }
.prose h2, .prose h3 { position: relative; }
.heading-anchor { margin-left: 8px; opacity: 0; color: var(--fg-muted); transition: opacity .15s; }
.prose h2:hover .heading-anchor, .prose h3:hover .heading-anchor { opacity: 1; text-decoration: none; }
.prose ul, .prose ol { padding-left: 1.4em; }
.prose li { margin: 4px 0; }
.inline-code { padding: .15em .4em; border-radius: 5px; background: var(--code-bg); border: 1px solid var(--border); font-size: .875em;
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; }
.table-wrap { overflow-x: auto; margin: 16px 0; border: 1px solid var(--border); border-radius: 8px; }
table { border-collapse: collapse; width: 100%; font-size: 14px; }
th, td { padding: 8px 12px; text-align: left; border-bottom: 1px solid var(--border); }
th { background: var(--bg-soft); font-weight: 600; }
tr:last-child td { border-bottom: 0; }

/* Callout */
.callout { margin: 20px 0; padding: 12px 16px; border: 1px solid var(--border); border-left: 4px solid var(--c); border-radius: 8px;
  background: color-mix(in srgb, var(--c) 8%, var(--bg)); }
.callout--info { --c: var(--info); } .callout--tip { --c: var(--tip); } .callout--warning { --c: var(--warning); } .callout--danger { --c: var(--danger); }
.callout__title { display: flex; gap: 8px; align-items: center; font-weight: 700; color: var(--c); margin-bottom: 4px; font-size: 14px; }
.callout__body { font-size: 15px; }

/* Code block */
.code-block { margin: 20px 0; border: 1px solid var(--border); border-radius: 10px; overflow: hidden; background: var(--code-bg); }
.code-block__bar { display: flex; align-items: center; gap: 12px; padding: 6px 8px 6px 14px; border-bottom: 1px solid var(--border); font-size: 12px; color: var(--fg-muted); }
.code-block__lang { text-transform: uppercase; font-weight: 700; letter-spacing: .05em; }
.code-block__file { font-family: ui-monospace, monospace; }
.code-block__copy { margin-left: auto; display: inline-flex; align-items: center; gap: 6px; padding: 4px 10px; font-size: 12px; cursor: pointer;
  border: 1px solid var(--border); border-radius: 6px; background: var(--bg-elev); color: var(--fg-muted); transition: all .2s ease; }
.code-block__copy:hover { color: var(--fg); border-color: var(--accent); }
.code-block__copy.is-copied { color: var(--tip); border-color: var(--tip); }
.code-block__copy.is-failed { color: var(--danger); border-color: var(--danger); }
.code-block__copy.is-copied .code-block__icon { animation: pop .3s ease; }
@keyframes pop { 0% { transform: scale(.4); } 70% { transform: scale(1.25); } 100% { transform: scale(1); } }
.code-block__pre { margin: 0; padding: 14px 16px; overflow-x: auto; font-size: 13.5px; line-height: 1.6; color: var(--code-fg);
  font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; tab-size: 2; }
.tok-comment { color: var(--tok-comment); font-style: italic; } .tok-string { color: var(--tok-string); } .tok-keyword { color: var(--tok-keyword); }
.tok-type { color: var(--tok-type); } .tok-number { color: var(--tok-number); } .tok-annotation { color: var(--tok-annotation); }
.tok-key { color: var(--tok-key); } .tok-punctuation { color: var(--tok-punct); } .tok-command { color: var(--tok-type); font-weight: 600; } .tok-flag { color: var(--tok-annotation); }

/* Pager */
.pager { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-top: 48px; }
.pager__link { display: flex; flex-direction: column; padding: 14px 16px; border: 1px solid var(--border); border-radius: 10px; transition: border-color .15s, transform .15s; }
.pager__link:hover { border-color: var(--accent); text-decoration: none; transform: translateY(-1px); }
.pager__link--next { text-align: right; }
.pager__label { font-size: 12px; color: var(--fg-muted); }
.pager__title { font-weight: 600; }

/* Quick start steps */
.steps { margin: 24px 0; padding: 20px; border: 1px solid var(--border); border-radius: 12px; background: var(--bg-soft); }
.steps__title { margin: 0 0 12px; font-size: 18px; }
.steps__list { list-style: none; margin: 0; padding: 0; display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 12px; }
.steps__item { display: flex; gap: 12px; align-items: flex-start; }
.steps__item p { margin: 2px 0 0; font-size: 14px; color: var(--fg-muted); }
.steps__num { flex: none; width: 28px; height: 28px; border-radius: 50%; display: grid; place-items: center; background: var(--accent); color: var(--accent-fg); font-weight: 700; font-size: 14px; }

/* Home */
.hero { padding: clamp(48px, 8vw, 96px) 0; border-bottom: 1px solid var(--border);
  background: radial-gradient(1200px 400px at 10% -10%, var(--accent-soft), transparent); }
.hero__inner { display: grid; grid-template-columns: 1.1fr 1fr; gap: 48px; align-items: center; }
@media (max-width: ${Breakpoints.drawer - 1}px) { .hero__inner { grid-template-columns: 1fr; } }
.badge { display: inline-block; padding: 4px 10px; border-radius: 999px; background: var(--accent-soft); color: var(--accent); font-size: 13px; font-weight: 600; }
.hero__title { margin: 16px 0; font-size: clamp(32px, 5vw, 52px); line-height: 1.1; letter-spacing: -.03em; }
.hero__subtitle { font-size: 18px; color: var(--fg-muted); max-width: 560px; }
.hero__actions { display: flex; flex-wrap: wrap; gap: 12px; margin-top: 24px; }
.btn { display: inline-flex; align-items: center; padding: 10px 18px; border-radius: 8px; font-weight: 600; border: 1px solid transparent; transition: transform .15s, background-color .15s; }
.btn:hover { text-decoration: none; transform: translateY(-1px); }
.btn--primary { background: var(--accent); color: var(--accent-fg); }
.btn--ghost { border-color: var(--border); color: var(--fg); background: var(--bg-elev); }
.hero__code .code-block { box-shadow: var(--shadow); }
.features { padding: 64px 0; }
.features__title { text-align: center; font-size: 28px; margin: 0 0 32px; }
.features__grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 20px; }
.feature-card { padding: 20px; border: 1px solid var(--border); border-radius: 12px; background: var(--bg-elev); transition: transform .15s, box-shadow .15s; }
.feature-card:hover { transform: translateY(-2px); box-shadow: var(--shadow); }
.feature-card__icon { font-size: 28px; }
.feature-card h3 { margin: 8px 0 4px; }
.feature-card p { margin: 0; color: var(--fg-muted); font-size: 14px; }
.not-found { padding: 96px 0; text-align: center; }

/* Footer */
.site-footer { border-top: 1px solid var(--border); padding: 24px 0; font-size: 13px; color: var(--fg-muted); }
.site-footer__inner { display: flex; flex-wrap: wrap; gap: 12px; justify-content: space-between; }

/* Layout diagram (introduction page) */
.layout-diagram { margin: 24px 0; padding: 20px; border: 1px solid var(--border); border-radius: 12px; background: var(--bg-soft); }
.ld__frames { display: flex; gap: 28px; align-items: flex-end; justify-content: center; flex-wrap: wrap; }
.ld__item { display: flex; flex-direction: column; align-items: center; gap: 8px; }
.ld__label { font-size: 13px; color: var(--fg-muted); font-weight: 600; }
.ld__frame { border: 2px solid var(--fg-muted); border-radius: 12px; background: var(--bg-elev); padding: 6px; display: flex; flex-direction: column; gap: 6px; }
.ld__frame--compact { width: 120px; height: 210px; }
.ld__frame--expanded { width: 340px; height: 210px; }
.ld__crumbs { font-size: 11px; color: var(--fg-muted); padding: 3px 8px; border-radius: 6px; background: var(--accent-soft); white-space: nowrap; overflow: hidden; }
.ld__columns { display: flex; gap: 6px; flex: 1; min-height: 0; }
.ld__pane { flex: 1; border: 1px solid var(--border); border-radius: 8px; overflow: hidden; display: flex; flex-direction: column; }
.ld__pane--left { flex: 0 0 40%; }
.ld__sash { width: 4px; border-radius: 4px; background: var(--accent); align-self: center; height: 60%; }
.ld__bar { font-size: 11px; font-weight: 600; padding: 6px 8px; background: var(--accent); color: var(--accent-fg); }
.ld__rows { display: flex; flex-direction: column; gap: 6px; padding: 8px; }
.ld__row { height: 10px; border-radius: 4px; background: var(--border); }
.layout-diagram figcaption { margin-top: 14px; text-align: center; font-size: 14px; color: var(--fg-muted); }
''';
