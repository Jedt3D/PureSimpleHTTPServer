/* PureSimpleHTTPServer — Demo Site App JS
   Features: theme toggle, active nav, copy-to-clipboard
   No dependencies. */

(function () {
  "use strict";

  // ── Theme toggle ────────────────────────────────────────────────
  const THEME_KEY = "pshs-theme";

  function applyTheme(theme) {
    document.documentElement.setAttribute("data-theme", theme);
    const btn = document.getElementById("theme-toggle");
    if (btn) btn.textContent = theme === "dark" ? "Light mode" : "Dark mode";
    try { localStorage.setItem(THEME_KEY, theme); } catch (_) {}
  }

  function initTheme() {
    let saved;
    try { saved = localStorage.getItem(THEME_KEY); } catch (_) {}
    const preferred = window.matchMedia("(prefers-color-scheme: dark)").matches
      ? "dark" : "light";
    applyTheme(saved || preferred);
  }

  function attachThemeToggle() {
    const btn = document.getElementById("theme-toggle");
    if (!btn) return;
    btn.addEventListener("click", function () {
      const current = document.documentElement.getAttribute("data-theme");
      applyTheme(current === "dark" ? "light" : "dark");
    });
  }

  // ── Active nav link ─────────────────────────────────────────────
  function markActiveNav() {
    const path = window.location.pathname.replace(/\/+$/, "") || "/";
    document.querySelectorAll("nav a").forEach(function (a) {
      const href = a.getAttribute("href").replace(/\/+$/, "") || "/";
      if (href === path) a.classList.add("active");
    });
  }

  // ── Copy-to-clipboard for <pre> blocks ──────────────────────────
  function attachCopyButtons() {
    document.querySelectorAll("pre").forEach(function (pre) {
      const btn = document.createElement("button");
      btn.className = "copy-btn";
      btn.textContent = "Copy";
      btn.addEventListener("click", function () {
        const code = pre.querySelector("code");
        const text = code ? code.innerText : pre.innerText;
        navigator.clipboard.writeText(text).then(function () {
          btn.textContent = "Copied!";
          setTimeout(function () { btn.textContent = "Copy"; }, 1800);
        }).catch(function () {
          btn.textContent = "Error";
          setTimeout(function () { btn.textContent = "Copy"; }, 1800);
        });
      });
      pre.appendChild(btn);
    });
  }

  // ── Bootstrap ──────────────────────────────────────────────────
  document.addEventListener("DOMContentLoaded", function () {
    initTheme();
    attachThemeToggle();
    markActiveNav();
    attachCopyButtons();
  });
}());
