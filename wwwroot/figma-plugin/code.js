// Figma Plugin: Xojo Syntax Highlight — Design System Creator
// Creates:
//   • "Xojo Design Tokens" variable collection with Dark + Light modes (requires paid plan)
//   • Two 1440px frames: Dark and Light — pixel-faithful replica of index.html

async function main() {
  var page = figma.currentPage;
  page.name = 'Xojo Syntax Highlight';

  // ── 1. Load fonts one by one ─────────────────────────────────────────
  await figma.loadFontAsync({ family: 'Inter', style: 'Regular' });
  await figma.loadFontAsync({ family: 'Inter', style: 'Semi Bold' });
  await figma.loadFontAsync({ family: 'Inter', style: 'Bold' });

  // ── 2. Helpers ───────────────────────────────────────────────────────
  function hex(h) {
    var s = h.replace('#', '');
    return {
      r: parseInt(s.slice(0, 2), 16) / 255,
      g: parseInt(s.slice(2, 4), 16) / 255,
      b: parseInt(s.slice(4, 6), 16) / 255,
    };
  }
  function solid(color) { return [{ type: 'SOLID', color: color }]; }

  // ── 3. Token values (mirrors CSS custom properties in index.html) ─────
  var DARK = {
    bgPage:      '#0d1117',
    bgCard:      '#161b22',
    bgInner:     '#21262d',
    border:      '#21262d',
    border2:     '#30363d',
    text:        '#c9d1d9',
    textMuted:   '#8b949e',
    textHeading: '#f0f6fc',
    footer:      '#484f58',
    link:        '#58a6ff',
    borderHover: '#1f6feb',
  };
  var LIGHT = {
    bgPage:      '#ffffff',
    bgCard:      '#f6f8fa',
    bgInner:     '#eaeef2',
    border:      '#d0d7de',
    border2:     '#d0d7de',
    text:        '#24292f',
    textMuted:   '#57606a',
    textHeading: '#1f2328',
    footer:      '#8b949e',
    link:        '#0969da',
    borderHover: '#1f6feb',
  };
  var ACCENT = {
    purple: '#c678dd',
    teal:   '#56b6c2',
    orange: '#d19a66',
    red:    '#e06c75',
    green:  '#98c379',
    yellow: '#e5c07b',
    gray:   '#5c6370',
  };

  // ── 4. Design tokens (requires Figma Professional+; skipped gracefully) ──
  var tokensNote = '';
  try {
    var col    = figma.variables.createVariableCollection('Xojo Design Tokens');
    var darkId = col.modes[0].modeId;
    col.renameMode(darkId, 'Dark');
    var lightId = col.addMode('Light');

    function colorVar(name, dk, lk) {
      var v = figma.variables.createVariable(name, col, 'COLOR');
      var d = hex(dk);
      var l = hex(lk || dk);
      v.setValueForMode(darkId,  { r: d.r, g: d.g, b: d.b, a: 1 });
      v.setValueForMode(lightId, { r: l.r, g: l.g, b: l.b, a: 1 });
      return v;
    }

    var darkKeys = Object.keys(DARK);
    for (var ki = 0; ki < darkKeys.length; ki++) {
      var k = darkKeys[ki];
      colorVar('theme/' + k, DARK[k], LIGHT[k]);
    }

    var accentKeys = Object.keys(ACCENT);
    for (var ai = 0; ai < accentKeys.length; ai++) {
      var ak = accentKeys[ai];
      colorVar('accent/' + ak, ACCENT[ak], ACCENT[ak]);
    }
    tokensNote = ' + design tokens';
  } catch (e) {
    tokensNote = ' (variables skipped: ' + String(e) + ')';
  }

  // ── 5. Color styles (Assets panel → Local styles → Color) ─────────────
  function paintStyle(name, hexColor) {
    var s = figma.createPaintStyle();
    s.name   = name;
    s.paints = solid(hex(hexColor));
    return s;
  }

  paintStyle('Dark/bg-page',      DARK.bgPage);
  paintStyle('Dark/bg-card',      DARK.bgCard);
  paintStyle('Dark/bg-inner',     DARK.bgInner);
  paintStyle('Dark/border',       DARK.border2);
  paintStyle('Dark/text',         DARK.text);
  paintStyle('Dark/text-muted',   DARK.textMuted);
  paintStyle('Dark/text-heading', DARK.textHeading);
  paintStyle('Dark/footer',       DARK.footer);
  paintStyle('Dark/link',         DARK.link);
  paintStyle('Dark/border-hover', DARK.borderHover);

  paintStyle('Light/bg-page',      LIGHT.bgPage);
  paintStyle('Light/bg-card',      LIGHT.bgCard);
  paintStyle('Light/bg-inner',     LIGHT.bgInner);
  paintStyle('Light/border',       LIGHT.border2);
  paintStyle('Light/text',         LIGHT.text);
  paintStyle('Light/text-muted',   LIGHT.textMuted);
  paintStyle('Light/text-heading', LIGHT.textHeading);
  paintStyle('Light/footer',       LIGHT.footer);
  paintStyle('Light/link',         LIGHT.link);
  paintStyle('Light/border-hover', LIGHT.borderHover);

  paintStyle('Accent/purple', ACCENT.purple);
  paintStyle('Accent/teal',   ACCENT.teal);
  paintStyle('Accent/orange', ACCENT.orange);
  paintStyle('Accent/red',    ACCENT.red);
  paintStyle('Accent/green',  ACCENT.green);
  paintStyle('Accent/yellow', ACCENT.yellow);
  paintStyle('Accent/gray',   ACCENT.gray);

  // ── 6. Text styles (Assets panel → Local styles → Text) ───────────────
  function textStyle(name, fontStyle, size, opts) {
    var s = figma.createTextStyle();
    s.name     = name;
    s.fontName = { family: 'Inter', style: fontStyle };
    s.fontSize = size;
    if (opts && opts.letterSpacing) { s.letterSpacing = opts.letterSpacing; }
    if (opts && opts.lineHeight)    { s.lineHeight    = opts.lineHeight; }
    return s;
  }

  textStyle('Heading/H1',         'Bold',      35,   { letterSpacing: { value: -1, unit: 'PERCENT' } });
  textStyle('Body/Default',       'Regular',   16,   { lineHeight: { value: 160, unit: 'PERCENT' } });
  textStyle('Card/Title',         'Semi Bold', 17,   {});
  textStyle('Card/Description',   'Regular',   13.6, { lineHeight: { value: 150, unit: 'PERCENT' } });
  textStyle('Badge/Label',        'Regular',   11,   {});
  textStyle('Footer/Link',        'Regular',   12.8, {});

  // ── 7. Components (Assets panel → Local components) ───────────────────
  // Placed off-canvas at y = -600 on a hidden area
  var COMP_X = 0;
  var COMP_Y = -600;

  // — Badge component —
  var badgeComp = figma.createComponent();
  badgeComp.name = 'Badge';
  badgeComp.resize(76, 22);
  badgeComp.x = COMP_X; badgeComp.y = COMP_Y;
  badgeComp.cornerRadius  = 20;
  badgeComp.fills         = solid(hex(DARK.bgInner));
  badgeComp.strokes       = solid(hex(DARK.border2));
  badgeComp.strokeWeight  = 1;
  page.appendChild(badgeComp);

  var badgeLabel = figma.createText();
  badgeLabel.fontName            = { family: 'Inter', style: 'Regular' };
  badgeLabel.characters          = 'JavaScript';
  badgeLabel.fontSize            = 11;
  badgeLabel.fills               = solid(hex(DARK.textMuted));
  badgeLabel.textAlignHorizontal = 'CENTER';
  badgeLabel.resize(68, 14);
  badgeLabel.x = 4; badgeLabel.y = 4;
  badgeComp.appendChild(badgeLabel);

  // — Card component —
  var cardComp = figma.createComponent();
  cardComp.name = 'Card';
  cardComp.resize(440, 190);
  cardComp.x = COMP_X + 120; cardComp.y = COMP_Y;
  cardComp.cornerRadius = 10;
  cardComp.fills        = solid(hex(DARK.bgCard));
  cardComp.strokes      = solid(hex(DARK.border));
  cardComp.strokeWeight = 1;
  page.appendChild(cardComp);

  var compTitle = figma.createText();
  compTitle.fontName   = { family: 'Inter', style: 'Semi Bold' };
  compTitle.characters = 'Library Name';
  compTitle.fontSize   = 17;
  compTitle.fills      = solid(hex(DARK.link));
  compTitle.x = 28; compTitle.y = 24;
  cardComp.appendChild(compTitle);

  var compBadge = badgeComp.createInstance();
  compBadge.x = 28 + Math.ceil(compTitle.width) + 10;
  compBadge.y = 27;
  cardComp.appendChild(compBadge);

  var compDesc = figma.createText();
  compDesc.fontName   = { family: 'Inter', style: 'Regular' };
  compDesc.characters = 'Short description of the syntax highlighting library and how to use it.';
  compDesc.fontSize   = 13.6;
  compDesc.fills      = solid(hex(DARK.textMuted));
  compDesc.lineHeight = { value: 150, unit: 'PERCENT' };
  compDesc.resize(384, 60);
  compDesc.x = 28; compDesc.y = 56;
  cardComp.appendChild(compDesc);

  var sampleDots = ['#c678dd', '#56b6c2', '#d19a66', '#e06c75', '#98c379', '#e5c07b'];
  for (var si = 0; si < sampleDots.length; si++) {
    var compDot = figma.createEllipse();
    compDot.resize(8, 8);
    compDot.x     = 28 + si * 12;
    compDot.y     = 162;
    compDot.fills = solid(hex(sampleDots[si]));
    cardComp.appendChild(compDot);
  }

  // — ThemeToggle component —
  var toggleComp = figma.createComponent();
  toggleComp.name         = 'ThemeToggle';
  toggleComp.resize(28, 26);
  toggleComp.x = COMP_X + 600; toggleComp.y = COMP_Y;
  toggleComp.cornerRadius = 6;
  toggleComp.fills        = [];
  toggleComp.strokes      = solid(hex(DARK.border2));
  toggleComp.strokeWeight = 1;
  page.appendChild(toggleComp);

  var toggleLabel = figma.createText();
  toggleLabel.fontName   = { family: 'Inter', style: 'Regular' };
  toggleLabel.characters = 'Sun';
  toggleLabel.fontSize   = 9;
  toggleLabel.fills      = solid(hex(DARK.textMuted));
  toggleLabel.x = 4; toggleLabel.y = 7;
  toggleComp.appendChild(toggleLabel);

  // ── 8. Card data ──────────────────────────────────────────────────────
  var CARDS = [
    {
      title: 'highlight.js',
      badge: 'JavaScript',
      desc:  'ES module factory function. Register once, works with any highlight.js theme. Ideal for static sites and Markdown renderers.',
      dots:  ['#c678dd', '#56b6c2', '#d19a66', '#e06c75', '#98c379', '#e5c07b', '#5c6370'],
    },
    {
      title: 'Prism.js',
      badge: 'JavaScript',
      desc:  'Self-executing IIFE that registers with Prism automatically. Load after prism.js and use language-xojo on any block.',
      dots:  ['#cc99cd', '#67cdcc', '#f08d49', '#7ec699', '#e5c07b', '#999999'],
    },
    {
      title: 'CodeMirror 6',
      badge: 'JavaScript',
      desc:  'StreamParser for CodeMirror 6. Fully editable code editor with Lezer highlight tags and One Dark / default light theme.',
      dots:  ['#c678dd', '#56b6c2', '#d19a66', '#e06c75', '#98c379', '#e5c07b', '#5c6370'],
    },
    {
      title: 'Pygments',
      badge: 'Python',
      desc:  'RegexLexer for server-side rendering with Python. Includes XojoOneDarkStyle and XojoOneLightStyle — no CDN dependencies.',
      dots:  ['#c678dd', '#56b6c2', '#d19a66', '#e06c75', '#98c379', '#e5c07b', '#5c6370'],
    },
  ];

  // ── 9. Build one landing-page frame ──────────────────────────────────
  function buildFrame(theme, offsetX) {
    var T        = theme === 'dark' ? DARK : LIGHT;
    var PAGE_W   = 1440;
    var CONTENT_W = 900;
    var PAD_X    = (PAGE_W - CONTENT_W) / 2;  // 270

    var frame = figma.createFrame();
    frame.name   = theme === 'dark' ? 'Dark' : 'Light';
    frame.resize(PAGE_W, 900);
    frame.x      = offsetX;
    frame.y      = 0;
    frame.fills  = solid(hex(T.bgPage));
    frame.clipsContent = false;
    page.appendChild(frame);

    var y = 48;

    // Theme toggle button
    var toggle = figma.createFrame();
    toggle.name         = 'ThemeToggle';
    toggle.resize(28, 26);
    toggle.x            = PAD_X + CONTENT_W - 28;
    toggle.y            = y;
    toggle.cornerRadius = 6;
    toggle.fills        = [];
    toggle.strokes      = solid(hex(T.border2));
    toggle.strokeWeight = 1;
    frame.appendChild(toggle);

    var iconTxt = figma.createText();
    iconTxt.fontName   = { family: 'Inter', style: 'Regular' };
    iconTxt.characters = theme === 'dark' ? 'Sun' : 'Moon';
    iconTxt.fontSize   = 9;
    iconTxt.fills      = solid(hex(T.textMuted));
    iconTxt.x = 4; iconTxt.y = 7;
    toggle.appendChild(iconTxt);

    // Hero heading
    y += 48;

    var h1 = figma.createText();
    h1.fontName            = { family: 'Inter', style: 'Bold' };
    h1.characters          = 'Xojo Syntax Highlight';
    h1.fontSize            = 35;
    h1.fills               = solid(hex(T.textHeading));
    h1.letterSpacing       = { value: -1, unit: 'PERCENT' };
    h1.textAlignHorizontal = 'CENTER';
    h1.resize(720, 44);
    h1.x = PAD_X + (CONTENT_W - 720) / 2;
    h1.y = y;
    frame.appendChild(h1);

    y += 56;

    // Hero subtitle
    var sub = figma.createText();
    sub.fontName            = { family: 'Inter', style: 'Regular' };
    sub.characters          = 'Syntax highlighting for the Xojo programming language — four library implementations with One Dark / One Light color schemes.';
    sub.fontSize            = 16;
    sub.fills               = solid(hex(T.textMuted));
    sub.textAlignHorizontal = 'CENTER';
    sub.lineHeight          = { value: 160, unit: 'PERCENT' };
    sub.resize(480, 52);
    sub.x = PAD_X + (CONTENT_W - 480) / 2;
    sub.y = y;
    frame.appendChild(sub);

    // Card grid
    y += 52 + 48;

    var CARD_W = 440;
    var CARD_H = 190;
    var GAP    = 16;
    var GRID_W = CARD_W * 2 + GAP;           // 896
    var GRID_X = PAD_X + (CONTENT_W - GRID_W) / 2;  // 272

    for (var i = 0; i < CARDS.length; i++) {
      var c    = CARDS[i];
      var col_ = i % 2;
      var row  = Math.floor(i / 2);
      var CX   = GRID_X + col_ * (CARD_W + GAP);
      var CY   = y + row * (CARD_H + GAP);

      var card = figma.createFrame();
      card.name          = 'Card - ' + c.title;
      card.resize(CARD_W, CARD_H);
      card.x             = CX;
      card.y             = CY;
      card.cornerRadius  = 10;
      card.fills         = solid(hex(T.bgCard));
      card.strokes       = solid(hex(T.border));
      card.strokeWeight  = 1;
      frame.appendChild(card);

      // Card title
      var titleNode = figma.createText();
      titleNode.fontName   = { family: 'Inter', style: 'Semi Bold' };
      titleNode.characters = c.title;
      titleNode.fontSize   = 17;
      titleNode.fills      = solid(hex(T.link));
      titleNode.x = 28; titleNode.y = 24;
      card.appendChild(titleNode);

      // Badge
      var BW    = c.badge === 'Python' ? 56 : 76;
      var badge = figma.createFrame();
      badge.name          = 'Badge';
      badge.resize(BW, 18);
      badge.x             = 28 + Math.ceil(titleNode.width) + 10;
      badge.y             = 27;
      badge.cornerRadius  = 20;
      badge.fills         = solid(hex(T.bgInner));
      badge.strokes       = solid(hex(T.border2));
      badge.strokeWeight  = 1;
      card.appendChild(badge);

      var badgeTxt = figma.createText();
      badgeTxt.fontName            = { family: 'Inter', style: 'Regular' };
      badgeTxt.characters          = c.badge;
      badgeTxt.fontSize            = 11;
      badgeTxt.fills               = solid(hex(T.textMuted));
      badgeTxt.textAlignHorizontal = 'CENTER';
      badgeTxt.resize(BW - 8, 14);
      badgeTxt.x = 4; badgeTxt.y = 2;
      badge.appendChild(badgeTxt);

      // Description
      var desc = figma.createText();
      desc.fontName   = { family: 'Inter', style: 'Regular' };
      desc.characters = c.desc;
      desc.fontSize   = 13.6;
      desc.fills      = solid(hex(T.textMuted));
      desc.lineHeight = { value: 150, unit: 'PERCENT' };
      desc.resize(CARD_W - 56, 72);
      desc.x = 28; desc.y = 56;
      card.appendChild(desc);

      // Token-colour dot strip
      for (var di = 0; di < c.dots.length; di++) {
        var dot = figma.createEllipse();
        dot.name  = 'token-dot';
        dot.resize(8, 8);
        dot.x     = 28 + di * 12;
        dot.y     = CARD_H - 28;
        dot.fills = solid(hex(c.dots[di]));
        card.appendChild(dot);
      }
    }

    // Footer
    y += 2 * (CARD_H + GAP) - GAP + 48;

    var footer = figma.createText();
    footer.fontName            = { family: 'Inter', style: 'Regular' };
    footer.characters          = 'github.com/worajedt/xojo-syntax-highlight';
    footer.fontSize            = 12.8;
    footer.fills               = solid(hex(T.footer));
    footer.textAlignHorizontal = 'CENTER';
    footer.resize(CONTENT_W, 20);
    footer.x = PAD_X;
    footer.y = y;
    frame.appendChild(footer);

    frame.resize(PAGE_W, y + 64);
    return frame;
  }

  // ── 10. Build both frames ─────────────────────────────────────────────
  var darkFrame  = buildFrame('dark',  0);
  var lightFrame = buildFrame('light', 1440 + 80);

  figma.viewport.scrollAndZoomIntoView([darkFrame, lightFrame]);
  figma.closePlugin('Done! Dark + Light frames created' + tokensNote);
}

main().catch(function(err) {
  figma.closePlugin('Error: ' + String(err));
});
