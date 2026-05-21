(function () {
  if (window.__ENV_WATERMARK__) return;
  window.__ENV_WATERMARK__ = true;

  // =============================
  // 环境配置（核心）
  // =============================
  const ENV_CONFIG = {
    dev: {
      text: "开发环境 DEV 开发环境 DEV",
      color: "#722ed1",
    },
    test: {
      text: "测试环境 TEST 测试环境 TEST",
      color: "#2f54eb",
    },
    uat: {
      text: "验收环境 UAT 验收环境 UAT",
      color: "#13c2c2",
    },
    sit: {
      text: "SIT环境 SIT环境",
      color: "#fa8c16",
    },
    staging: {
      text: "预发环境 STAGING 预发环境 STAGING",
      color: "#eb2f96",
    },
  };

  // =============================
  // 环境识别
  // =============================
  function detectEnv() {
    const host = location.hostname.toLowerCase();

    // 本地环境
    if (
      host === "localhost" ||
      host === "127.0.0.1" ||
      host.endsWith(".local")
    ) {
      return { key: "dev", config: ENV_CONFIG.dev };
    }

    for (const key in ENV_CONFIG) {
      if (
        host === key ||
        host.startsWith(key + ".") ||
        host.endsWith("." + key) ||
        host.includes("." + key + ".")
      ) {
        return { key, config: ENV_CONFIG[key] };
      }
    }

    return null;
  }

  const env = detectEnv();
  if (!env) return;

  const TEXT = env.config.text;
  const COLOR = env.config.color;

  let bannerEl = null;
  let idleTimer = null;
  let isIdle = false;

  // =============================
  // 主题检测
  // =============================
  function isDarkMode() {
    return window.matchMedia &&
      window.matchMedia("(prefers-color-scheme: dark)").matches;
  }

  // =============================
  // 顶部条幅
  // =============================
  function createBanner() {
    if (document.getElementById("__env_banner__")) return;

    const banner = document.createElement("div");
    banner.id = "__env_banner__";
    banner.innerText = TEXT;

    Object.assign(banner.style, {
      position: "fixed",
      top: "0",
      left: "0",
      width: "100%",
      height: "46px",
      lineHeight: "46px",
      background: `linear-gradient(90deg, ${COLOR}, #ff3d00)`,
      color: "#fff",
      fontSize: "17px",
      fontWeight: "bold",
      textAlign: "center",
      zIndex: "999999",
      pointerEvents: "none",
      letterSpacing: "3px",
      textShadow: "0 1px 2px rgba(0,0,0,0.4)",
      transition: "all 0.4s ease",
      boxShadow: `0 2px 10px ${COLOR}99`,
    });

    document.body.appendChild(banner);
    bannerEl = banner;

    startBreathingEffect();
    initIdleDetection();
  }

  // =============================
  // 呼吸动画
  // =============================
  function startBreathingEffect() {
    let visible = true;
    setInterval(() => {
      if (!bannerEl || isIdle) return;

      visible = !visible;

      bannerEl.style.opacity = visible ? "1" : "0.75";
      bannerEl.style.boxShadow = visible
        ? `0 2px 14px ${COLOR}`
        : `0 2px 6px ${COLOR}66`;
    }, 900);
  }

  // =============================
  // idle 检测
  // =============================
  function initIdleDetection() {
    const IDLE_TIME = 3000;

    function resetTimer() {
      if (idleTimer) clearTimeout(idleTimer);

      if (isIdle) {
        isIdle = false;
        if (bannerEl) {
          bannerEl.style.transform = "scale(1)";
          bannerEl.style.boxShadow = `0 2px 10px ${COLOR}99`;
        }
      }

      idleTimer = setTimeout(() => {
        isIdle = true;
        if (bannerEl) {
          bannerEl.style.transform = "scale(1.05)";
          bannerEl.style.boxShadow = `0 4px 22px ${COLOR}`;
        }
      }, IDLE_TIME);
    }

    ["mousemove", "keydown", "scroll", "touchstart"].forEach((event) => {
      window.addEventListener(event, resetTimer, { passive: true });
    });

    resetTimer();
  }

  // =============================
  // 水印
  // =============================
  function createWatermark() {
    const canvas = document.createElement("canvas");
    const ctx = canvas.getContext("2d");

    const ratio = window.devicePixelRatio || 1;
    const width = 400;
    const height = 260;

    canvas.width = width * ratio;
    canvas.height = height * ratio;
    ctx.scale(ratio, ratio);

    ctx.rotate(-Math.PI / 6);

    // 字体
    ctx.font = "20px Arial";

    ctx.fillStyle = isDarkMode()
      ? `${COLOR}33`
      : `${COLOR}22`;

    ctx.fillText(TEXT, 40, 200);

    return canvas.toDataURL();
  }

  function applyWatermark() {
    if (document.getElementById("__env_watermark__")) return;

    const wm = document.createElement("div");
    wm.id = "__env_watermark__";

    Object.assign(wm.style, {
      position: "fixed",
      top: "0",
      left: "0",
      width: "100%",
      height: "100%",
      zIndex: "999998",
      pointerEvents: "none",
      backgroundImage: `url(${createWatermark()})`,
      backgroundRepeat: "repeat",
      backgroundSize: "300px 200px",
    });

    document.body.appendChild(wm);
  }

  // =============================
  // SPA 保护
  // =============================
  function observeDom() {
    const observer = new MutationObserver(() => {
      if (!document.getElementById("__env_banner__")) {
        createBanner();
      }
      if (!document.getElementById("__env_watermark__")) {
        applyWatermark();
      }
    });

    observer.observe(document.body, {
      childList: true,
      subtree: true,
    });
  }

  // =============================
  // 初始化
  // =============================
  function init() {
    createBanner();
    applyWatermark();
    observeDom();

    if (!document.title.includes(env.key.toUpperCase())) {
      document.title = `【${env.key.toUpperCase()}】` + document.title;
    }
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
