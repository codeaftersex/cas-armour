
(() => {
  "use strict";

  const RES_NAME = (typeof GetParentResourceName === "function") ? GetParentResourceName() : "cas-armour";

  const STATE = {
    open: false,
    dragging: false,
    config: null,
    equipment: {},
    inventory: [],
    stats: {},
    activeSetBonuses: [],
    activePassives: [],
    query: "",
    filterWeight: "all",
    selectedSetId: null,
    focusedSlot: null,
    bonePositions: null,
    ui: {
      $armorUI: null,
      $setsUI: null,
      $invGrid: null,
      $floatingSlots: null,
      $boneLines: null,
      $statsGrid: null,
      $selected: null,
      $selectedIcon: null,
      $selectedSlot: null,
      $selectedStats: null,
      $setsList: null,
      $setDetails: null,
      $hud: null,
      $hudBars: null,
    }
  };

const RENDER = {
  rafPending: false,
  dirtyHud: false,
  dirtyMain: false,
  lastMainTs: 0,
  mainMinIntervalMs: 33,
  hudRows: new Map(),
};

function markHudDirty(){
  RENDER.dirtyHud = true;
  scheduleRender();
}

function markMainDirty(){
  RENDER.dirtyMain = true;
  scheduleRender();
}

function scheduleRender(){
  if(RENDER.rafPending) return;
  RENDER.rafPending = true;
  requestAnimationFrame((ts) => {
    RENDER.rafPending = false;
    flushRender(ts);
  });
}

function flushRender(ts){
  if(RENDER.dirtyHud){
    RENDER.dirtyHud = false;
    markHudDirty();
  }

  if(!STATE.open) return;

  if(RENDER.dirtyMain){
    if((ts - RENDER.lastMainTs) < RENDER.mainMinIntervalMs){
      scheduleRender();
      return;
    }

    RENDER.lastMainTs = ts;
    RENDER.dirtyMain = false;

    renderInventory();
    renderEquipment();
    renderStats();

    if(STATE.ui.$setsUI && STATE.ui.$setsUI.hasClass("is-active")){
      renderSetsList();
      if(STATE.selectedSetId){
        renderSetDetails(STATE.selectedSetId);
      }
    }
  }
}

  const SLOT_LABEL = {
    head: "HEAD",
    chest: "CHEST",
    vest: "VEST",
    pants: "PANTS",
    boots: "BOOTS",
    gloves: "GLOVES",
    belt: "BELT",
    amulet: "AMULET",
    trinket1: "TRINKET 1",
    trinket2: "TRINKET 2",
  };

  const PASSIVE_LABEL = {
    wolf_detection_reduction: "Wolf Detection Reduction",
    bear_charge_resistance:   "Bear Charge Resistance",
    bullet_dodge_chance:      "Bullet Dodge Chance",
    enemy_detection_boost:    "Enemy Detection Boost",
    poison_aura:              "Poison Aura",
    assassination_expertise:  "Assassination Expertise",
    quickdraw_mastery:        "Quickdraw Mastery",
  };

  const STAT_LABEL = {
    armorBase: "ARMOR",
    bulletResist: "BULLET RESIST",
    meleeResist: "MELEE RESIST",
    animalResist: "ANIMAL RESIST",
    fallResist: "FALL RESIST",
    explosionResist: "EXPLOSION RESIST",
    coldResist: "COLD RESIST",
    heatResist: "HEAT RESIST",
    stealthModifier: "STEALTH",
    staminaCostModifier: "STAMINA COST",
    moveSpeedModifier: "MOVE SPEED",
    noiseModifier: "NOISE",
  };

  const STAT_ICON = {
    armorBase:          "assets/icons/armor.png",
    bulletResist:       "assets/icons/bullet.png",
    meleeResist:        "assets/icons/melee.png",
    animalResist:       "assets/icons/animal.png",
    fallResist:         "assets/icons/fall.png",
    explosionResist:    "assets/icons/explosion.png",
    coldResist:         "assets/icons/cold.png",
    heatResist:         "assets/icons/heat.png",
    stealthModifier:    "assets/icons/stealth.png",
    staminaCostModifier:"assets/icons/stamina.png",
    moveSpeedModifier:  "assets/icons/speed.png",
    noiseModifier:      "assets/icons/noise.png",
  };

  const STAT_COLOR = {
    armorBase:          "#C9A94E",
    bulletResist:       "#AD3838",
    meleeResist:        "#8B6B3E",
    animalResist:       "#6B8E4E",
    fallResist:         "#7A7A7A",
    explosionResist:    "#D4672A",
    coldResist:         "#4A8DB7",
    heatResist:         "#C45C2C",
    stealthModifier:    "#6B5B8D",
    staminaCostModifier:"#3BAA6B",
    moveSpeedModifier:  "#5A9EAD",
    noiseModifier:      "#8C7B6B",
  };

  const STAT_BAR_MAX = {
    armorBase:           50,
    bulletResist:        60,
    meleeResist:         30,
    animalResist:        40,
    fallResist:          25,
    explosionResist:     20,
    coldResist:          45,
    heatResist:          35,
    stealthModifier:     70,
    staminaCostModifier: 20,
    noiseModifier:       50,
    deadeyeDrainModifier:12,
    intimidation:        20,
    poisonResist:        55,
    moveSpeedModifier:   10,
  };
  const STAT_BAR_DEFAULT_MAX = 50;

const VORP_ITEM_ICON_BASE = "https://cfx-nui-vorp_inventory/html/img/items/";
function normalizeItemNameForIcon(name){
  return safeStr(name).trim().toLowerCase();
}
function vorpItemIconUrl(itemName){
  const n = normalizeItemNameForIcon(itemName);
  return n ? `${VORP_ITEM_ICON_BASE}${n}.png` : "assets/testitem.png";
}
function setImageWithFallback($img, url, fallback){
  if(!$img || $img.length === 0) return;
  const el = $img.get(0);
  if(!el) return;
  el.onerror = function(){
    el.onerror = null;
    el.src = fallback;
  };
  el.src = url;
}
function setItemIcon($img, itemName, piece){
  const fallback = (piece && piece.icon) ? piece.icon : "assets/testitem.png";
  setImageWithFallback($img, vorpItemIconUrl(itemName), fallback);
}

const PRELOAD = {
  didCore: false,
  corePromise: null,
  imgCache: new Map(),
  iconCache: new Set(),
};

function collectAssetPathsFromDOM(){
  try{
    const html = document.documentElement ? document.documentElement.outerHTML : "";
    const reAssets = /assets\/[a-zA-Z0-9_\-\/\.]+/g;
    const found = html.match(reAssets) || [];
    return Array.from(new Set(found.filter(p => !/\.(ttf|otf|woff2?)$/i.test(p))));
  }catch(e){
    return [];
  }
}

function preloadImages(paths, timeoutMs){
  const unique = Array.from(new Set((paths || []).filter(Boolean)));
  if(unique.length === 0) return Promise.resolve();

  const timeout = Math.max(300, Number(timeoutMs || 1600));
  let done = 0;

  return new Promise(resolve => {
    const timer = setTimeout(resolve, timeout);

    unique.forEach(src => {
      if(PRELOAD.imgCache.has(src)){
        done++;
        if(done >= unique.length){
          clearTimeout(timer);
          resolve();
        }
        return;
      }

      const img = new Image();
      PRELOAD.imgCache.set(src, img);

      img.onload = img.onerror = () => {
        done++;
        if(done >= unique.length){
          clearTimeout(timer);
          resolve();
        }
      };
      img.decoding = "async";
      img.src = src;
    });
  });
}

function collectSetImages(){
  const sets = setsCfg();
  const paths = [];
  for(const [, set] of Object.entries(sets)){
    if(set && set.image) paths.push(set.image);
  }
  return paths;
}

function preloadCoreAssets(){
  if(PRELOAD.corePromise) return PRELOAD.corePromise;

  const domAssets = collectAssetPathsFromDOM();
  const setImages = collectSetImages();
  const allAssets = domAssets.concat(setImages);
  PRELOAD.corePromise = preloadImages(allAssets, 2500).finally(() => {
    PRELOAD.didCore = true;
  });

  return PRELOAD.corePromise;
}

function preloadInventoryIcons(items){
  const maxIcons = 40;
  let n = 0;
  for(const it of (items || [])){
    if(n >= maxIcons) break;
    const itemName = safeStr(it && (it.name || it.itemName || it.item)).trim();
    if(!itemName) continue;

    const key = normalizeItemNameForIcon(itemName);
    if(!key || PRELOAD.iconCache.has(key)) continue;
    PRELOAD.iconCache.add(key);

    const url = vorpItemIconUrl(itemName);
    if(url.startsWith("https://cfx-nui-")){
      n++;
      const img = new Image();
      img.decoding = "async";
      img.src = url;
    }
  }
}

function setLoading(active){
  const el = document.getElementById("cas-loading");
  if(!el) return;
  if(active) el.classList.add("is-active");
  else el.classList.remove("is-active");
}

function activatePage(which){
  const $armor = STATE.ui.$armorUI;
  const $sets = STATE.ui.$setsUI;
  if(!$armor || !$sets) return;

  if(which === "sets"){
    $sets.addClass("is-active");
    $armor.removeClass("is-active");
  } else {
    $armor.addClass("is-active");
    $sets.removeClass("is-active");
  }
}

function normalizeBonuses(bonuses){
  if(!bonuses) return {};
  if(Array.isArray(bonuses)){
    const out = {};
    bonuses.forEach((v, i) => {
      if(v && typeof v === "object") out[String(i)] = v;
    });
    return out;
  }
  if(typeof bonuses === "object"){
    const out = {};
    for(const [k, v] of Object.entries(bonuses)){
      if(v && typeof v === "object") out[String(k)] = v;
    }
    return out;
  }
  return {};
}

  function safeStr(v){ return (v === null || v === undefined) ? "" : String(v); }
  function escapeHtml(str){ return safeStr(str).replace(/[&<>"']/g, m => ({ "&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;" }[m])); }

  function encodeMeta(meta){
    try { return btoa(unescape(encodeURIComponent(JSON.stringify(meta || {})))); } catch(e){ return ""; }
  }
  function decodeMeta(b64){
    if(!b64) return {};
    try { return JSON.parse(decodeURIComponent(escape(atob(b64)))); } catch(e){ return {}; }
  }

  function postNui(action, payload){
    return $.post(`https://${RES_NAME}/${action}`, JSON.stringify(payload || {}));
  }

  function piecesCfg(){ return (STATE.config && (STATE.config.armorPieces || STATE.config.pieces)) || {}; }
  function setsCfg(){ return (STATE.config && (STATE.config.armorSets || STATE.config.sets)) || {}; }
  function slotsCfg(){ return (STATE.config && STATE.config.slots) || Object.keys(SLOT_LABEL); }

  function pieceByItemName(itemName){
    const pcs = piecesCfg();
    if(!itemName) return null;
    if(pcs[itemName]) return pcs[itemName];

    for(const [pid, p] of Object.entries(pcs)){
      if(p && (p.itemName === itemName)) return p;
      if(p && (p.itemName === itemName || pid === itemName)) return p;
    }
    return null;
  }

  function getPieceIdFromMetaOrName(itemName, meta){
    const pcs = piecesCfg();
    if(meta && meta.casArmour && meta.casArmour.pieceId && pcs[meta.casArmour.pieceId]) return meta.casArmour.pieceId;
    if(pcs[itemName]) return itemName;
    for(const [pid, p] of Object.entries(pcs)){
      if(p && p.itemName === itemName) return pid;
    }
    return itemName;
  }

  function isTrinketSlot(slot){ return slot === "trinket1" || slot === "trinket2"; }
  function isTrinketPiece(piece){
    if(!piece) return false;
    const s = safeStr(piece.slot).toLowerCase();
    return s === "trinket" || s === "trinket1" || s === "trinket2";
  }

  function slotCompatible(piece, targetSlot){
    if(!piece || !targetSlot) return false;

    const want = safeStr(piece.slot).toLowerCase();
    const tgt = safeStr(targetSlot).toLowerCase();

    if(isTrinketPiece(piece)){
      return isTrinketSlot(tgt);
    }

    return want === tgt;
  }

  function openUI(){
  STATE.open = true;

  $("body").addClass("cas-stage cas-ui-open");

  if(!STATE.ui.$armorUI) cacheUI();

  setLoading(true);
  preloadCoreAssets().finally(() => {
    setTimeout(() => setLoading(false), 120);
  });

  activatePage("armor");
  clearSelectedPanel();
  markMainDirty();
  postNui("cas_armour:requestData");
}

function closeUI(){
  STATE.open = false;
  STATE.focusedSlot = null;

  if(!STATE.ui.$armorUI) cacheUI();

  STATE.ui.$armorUI.removeClass("is-active");
  STATE.ui.$setsUI.removeClass("is-active");
  setLoading(false);

  const svg = document.getElementById("cas-bone-lines");
  if(svg) svg.innerHTML = "";

  $("body").removeClass("cas-ui-open");

  setTimeout(() => {
    $("body").removeClass("cas-stage");
    clearSelectedPanel();
  }, 220);

  postNui("cas_armour:close");
}

function showSets(){
  activatePage("sets");
  clearSelectedPanel();
  markMainDirty();
}

  function showArmor(){
  activatePage("armor");
  clearSelectedPanel();
  markMainDirty();
}

  function formatSigned(v){
    const n = Number(v);
    if(Number.isFinite(n)){
      if(n > 0) return `+${n}`;
      return `${n}`;
    }
    return safeStr(v);
  }

  function renderSelectedRow(label, value){
    return `
      <div class="flex justify-between w-full items-center">
        <div class="text-md rdr-lino text-white">${escapeHtml(label)}</div>
        <div class="text-[#CD9B6A] rdr-lino">${escapeHtml(value)}</div>
      </div>
    `;
  }

  function clearSelectedPanel(){
    if(!STATE.ui.$selected || STATE.ui.$selected.length === 0) return;
    STATE.ui.$selected.stop(true).show();
    const $contentRow = STATE.ui.$selectedIcon.closest(".flex.items-start");
    $contentRow.hide();
    STATE.ui.$selectedStats.empty();
    STATE.ui.$selected.find(".cas-empty-hint").remove();
    STATE.ui.$selected.append(`<div class="cas-empty-hint absolute inset-0 flex items-center justify-center pointer-events-none" style="z-index:5;"><div class="rdr-lino text-md text-center" style="color:rgba(255,255,255,0.5);">Select an item to view details</div></div>`);
  }

  function setSelectedPanelFor(itemName, meta, forcedSlotLabel){
    const piece = pieceByItemName(itemName);
    if(!piece){
      clearSelectedPanel();
      return;
    }

    const slotLabel = forcedSlotLabel || (SLOT_LABEL[piece.slot] || safeStr(piece.slot).toUpperCase());

    STATE.ui.$selected.find(".cas-empty-hint").remove();
    const $contentRow = STATE.ui.$selectedIcon.closest(".flex.items-start");
    $contentRow.show();
    STATE.ui.$selectedIcon.show();
    setItemIcon(STATE.ui.$selectedIcon, itemName, piece);
    STATE.ui.$selectedSlot.show().text(slotLabel);

    const casMeta = (meta && meta.casArmour) ? meta.casArmour : (meta || {});
    const rows = [];

    if(casMeta && casMeta.condition !== undefined && casMeta.maxCondition !== undefined){
      rows.push(renderSelectedRow("CONDITION", `${casMeta.condition}/${casMeta.maxCondition}`));
    }

    const stats = piece.stats || {};
    for(const [k, v] of Object.entries(stats)){
      if(v === 0 || v === null || v === undefined) continue;
      rows.push(renderSelectedRow(STAT_LABEL[k] || k.toUpperCase(), formatSigned(v)));
    }

    if(piece.set){
      const set = setsCfg()[piece.set];
      rows.push(renderSelectedRow("SET", set ? (set.name || piece.set) : piece.set));
    }

    if(!rows.length){
      rows.push(`<div class="text-md hapna" style="color:rgba(255,255,255,0.4);">No stats.</div>`);
    }

    STATE.ui.$selectedStats.html(rows.join(""));
    STATE.ui.$selected.stop(true).show();
  }

function buildSlotsIfNeeded(){
    const $container = STATE.ui.$floatingSlots;
    if(!$container || $container.length === 0) return;
    if($container.find(".cas-slot").length > 0) return;

    const slots = slotsCfg();
    const html = slots.map(slot => {
      const label = SLOT_LABEL[slot] || slot.toUpperCase();
      return `
        <div class="cas-floating-slot-wrapper" data-slot="${escapeHtml(slot)}">
          <div class="cas-slot cas-slot-circle" data-slot="${escapeHtml(slot)}">
            <div class="cas-slot-ring"></div>
            <div class="cas-slot-item"></div>
          </div>
          <div class="cas-slot-label rdr-lino">${escapeHtml(label)}</div>
        </div>
      `;
    }).join("");

    $container.html(html);

    bindDroppables();
    positionFloatingSlots();
  }

  function bindDroppables(){
    $("#cas-floating-slots .cas-slot").each(function(){
      const $slot = $(this);
      try { $slot.droppable("destroy"); } catch(e){}

      $slot.droppable({
        accept: ".cas-inv-item",
        tolerance: "pointer",
        hoverClass: "cas-slot-hover",
        drop: function(event, ui){
          const targetSlot = $slot.data("slot");
          const $it = $(ui.draggable);
          const itemName = $it.data("itemname");
          const itemId = $it.data("itemid") || null;
          const meta = decodeMeta($it.data("meta") || "");
          const piece = pieceByItemName(itemName);

          if(!piece){
            flashInvalid($slot);
            return;
          }

          if(!slotCompatible(piece, targetSlot)){
            flashInvalid($slot);
            return;
          }

          postNui("cas_armour:equip", {
            itemName: itemName,
            itemId: itemId,
            targetSlot: targetSlot,
            metadata: meta
          });
        }
      });
    });
  }

  let invDragTimer = null;

  function flashInvalid($el){
    $el.addClass("cas-invalid");
    setTimeout(() => $el.removeClass("cas-invalid"), 220);
  }

  function renderInventory(){
    const $grid = STATE.ui.$invGrid;
    if($grid.length === 0) return;

    const q = (STATE.query || "").toLowerCase().trim();
    const w = (STATE.filterWeight || "all").toLowerCase();

    const items = (STATE.inventory || []).filter(it => {
      const itemName = safeStr(it.name || it.itemName || it.item);
      const piece = pieceByItemName(itemName);
      if(!piece) return false;
      if(w !== "all" && safeStr(piece.weight).toLowerCase() !== w) return false;

      const label = safeStr(it.label || piece.name || itemName).toLowerCase();
      return !q || label.includes(q) || itemName.toLowerCase().includes(q);
    });

    if(items.length === 0){
      $grid.empty();
      return;
    }

    const html = items.map(it => {
      const itemName = it.name || it.itemName || it.item;
      const piece = pieceByItemName(itemName);
      const meta = (typeof it.metadata === "string") ? safeJsonParse(it.metadata) : (it.metadata || {});
      const casMeta = (meta && meta.casArmour) ? meta.casArmour : meta;
      const cond = (casMeta && casMeta.condition !== undefined && casMeta.maxCondition !== undefined)
        ? `${casMeta.condition}/${casMeta.maxCondition}`
        : "";
      const qty = it.count || it.amount || 1;

      const label = it.label || (piece && piece.name) || itemName;
      const fallbackIcon = (piece && piece.icon) ? piece.icon : "assets/testitem.png";
      const icon = vorpItemIconUrl(itemName);
      const metaEnc = encodeMeta(meta);

      return `
        <div class="bg-[url(assets/itembg.png)] flex items-center h-[90px] bgfull justify-center relative cas-inv-item"
             data-itemname="${escapeHtml(itemName)}"
             data-itemid="${escapeHtml(it.id || it.itemId || it.mainid || it.uniqueid || "")}"
             data-meta="${escapeHtml(metaEnc)}">
          <img loading="lazy" decoding="async" src="${escapeHtml(icon)}" onerror="this.onerror=null;this.src='${escapeHtml(fallbackIcon)}';" class="w-[80%] object-contain pointer-events-none" alt="" />
          ${cond ? `<div class="absolute bottom-1 right-2 text-xs text-[#CFCCCC] rdr-lino pointer-events-none">${escapeHtml(cond)}</div>` : ""}
          ${qty > 1 ? `<div class="absolute top-1 left-2 text-xs text-[#CFCCCC] rdr-lino pointer-events-none">x${escapeHtml(qty)}</div>` : ""}
          <div class="absolute -bottom-6 left-1/2 -translate-x-1/2 text-[11px] text-[#CFCCCC] rdr-lino w-[110px] text-center truncate pointer-events-none">${escapeHtml(label)}</div>
        </div>
      `;
    }).join("");

    $grid.html(html);
if(invDragTimer) clearTimeout(invDragTimer);
invDragTimer = setTimeout(() => {
  $(".cas-inv-item").draggable({
    helper: function(){
      const $icon = $(this).find("img").first();
      const iconSrc = $icon.length ? $icon.attr("src") : "assets/testitem.png";
      const scale = parseFloat(getComputedStyle(document.querySelector(".ui-frame")).getPropertyValue("--ui-scale")) || 1;
      const size = Math.round(60 * scale);

      return $("<img>").attr("src", iconSrc).css({
        width: size + "px",
        height: size + "px",
        objectFit: "contain",
        pointerEvents: "none",
        filter: "drop-shadow(0 2px 8px rgba(0,0,0,0.7))",
      });
    },
    appendTo: "body",
    cursorAt: { left: 30, top: 30 },
    zIndex: 999999,
    revert: "invalid",
    revertDuration: 200,
    start: function(){
      STATE.dragging = true;
      $(this).css("opacity", 0.6);
    },
    stop: function(){
      $(this).css("opacity", 1.0);
      setTimeout(() => { STATE.dragging = false; }, 0);
    },
  });
}, 0);
  }

  function safeJsonParse(s){
    try { return JSON.parse(s); } catch(e){ return {}; }
  }

  function renderEquipment(){
    buildSlotsIfNeeded();

    const eq = STATE.equipment || {};
    for(const slot of slotsCfg()){
      const $slotCircle = $(`#cas-floating-slots .cas-slot[data-slot="${slot}"]`);
      const $slotItem = $slotCircle.find(".cas-slot-item");
      if($slotItem.length === 0) continue;

      const ent = eq[slot];
      if(!ent || !ent.itemName){
        $slotItem.empty();
        $slotCircle.removeClass("cas-slot-equipped");
        continue;
      }

      $slotCircle.addClass("cas-slot-equipped");

      const piece = pieceByItemName(ent.itemName);
      const fallbackIcon = (piece && piece.icon) ? piece.icon : "assets/testitem.png";
      const icon = vorpItemIconUrl(ent.itemName);
      const maxC = Number(ent.maxCondition || 0);
      const curC = Number(ent.condition || 0);
      const condPct = maxC > 0 ? Math.round((curC / maxC) * 100) : 0;

      const meta = { casArmour: { pieceId: ent.pieceId, condition: ent.condition, maxCondition: ent.maxCondition } };
      const metaEnc = encodeMeta(meta);

      $slotItem.html(`
        <div class="cas-eq-item"
             data-slot="${escapeHtml(slot)}"
             data-itemname="${escapeHtml(ent.itemName)}"
             data-meta="${escapeHtml(metaEnc)}">
          <img loading="lazy" decoding="async" src="${escapeHtml(icon)}" onerror="this.onerror=null;this.src='${escapeHtml(fallbackIcon)}';" class="cas-slot-icon" alt="" />
        </div>
      `);

      $slotCircle.get(0).style.setProperty("--cond-pct", condPct + "%");
    }

    $(".cas-eq-item").each(function(){
      const $el = $(this);
      try { $el.draggable("destroy"); } catch(e){}

      $el.draggable({
        helper: function(){
          const $icon = $(this).find("img").first();
          const iconSrc = $icon.length ? $icon.attr("src") : "assets/testitem.png";
          const scale = parseFloat(getComputedStyle(document.querySelector(".ui-frame")).getPropertyValue("--ui-scale")) || 1;
          const size = Math.round(60 * scale);

          return $("<img>").attr("src", iconSrc).css({
            width: size + "px",
            height: size + "px",
            objectFit: "contain",
            pointerEvents: "none",
            filter: "drop-shadow(0 2px 8px rgba(0,0,0,0.7))",
          });
        },
        appendTo: "body",
        cursorAt: { left: 30, top: 30 },
        zIndex: 999999,
        revert: "invalid",
        revertDuration: 200,
        start: function(){
          STATE.dragging = true;
          $(this).css("opacity", 0.4);
        },
        stop: function(){
          $(this).css("opacity", 1.0);
          setTimeout(() => { STATE.dragging = false; }, 0);
        },
      });
    });
  }

const FRAME_W = 1920;
const FRAME_H = 1080;
const SLOT_SIZE = 66;
const LABEL_H  = 18;
const SLOT_TOTAL_H = SLOT_SIZE + LABEL_H + 4;

const SLOT_POSITIONS = {
  head:     { x: 660,  y: 120 },
  chest:    { x: 660,  y: 280 },
  belt:     { x: 660,  y: 440 },
  gloves:   { x: 660,  y: 600 },
  boots:    { x: 660,  y: 760 },
  amulet:   { x: 1194, y: 120 },
  vest:     { x: 1194, y: 280 },
  trinket1: { x: 1194, y: 440 },
  trinket2: { x: 1194, y: 600 },
  pants:    { x: 1194, y: 760 },
};

function positionFloatingSlots(){
  const $container = STATE.ui.$floatingSlots;
  if(!$container || $container.length === 0) return;

  const wrappers = $container.find(".cas-floating-slot-wrapper");
  if(wrappers.length === 0) return;

  const all = [];

  wrappers.each(function(){
    const $w = $(this);
    const slot = $w.data("slot");
    const fixedPos = SLOT_POSITIONS[slot];
    if(!fixedPos) return;

    const pos = STATE.bonePositions && STATE.bonePositions[slot];
    const boneX = pos ? (pos.x * FRAME_W) : (FRAME_W / 2);
    const boneY = pos ? (pos.y * FRAME_H) : (FRAME_H / 2);
    const side = pos ? pos.side : "left";

    const entry = { $w, slot, boneX, boneY, side, finalX: fixedPos.x, finalY: fixedPos.y };

    $w.css({
      position: "absolute",
      left: fixedPos.x + "px",
      top: fixedPos.y + "px",
      "pointer-events": "auto",
      "z-index": 20,
    });

    all.push(entry);
  });

  drawBoneLines(all);
}

function drawBoneLines(slotEntries){
  const svg = document.getElementById("cas-bone-lines");
  if(!svg) return;

  svg.innerHTML = "";

  if(!slotEntries || slotEntries.length === 0) return;
  if(!STATE.bonePositions) return;

  const ns = "http://www.w3.org/2000/svg";
  const halfSlot = SLOT_SIZE / 2;

  const defs = document.createElementNS(ns, "defs");
  const filter = document.createElementNS(ns, "filter");
  filter.setAttribute("id", "bone-line-glow");
  filter.setAttribute("x", "-50%");
  filter.setAttribute("y", "-50%");
  filter.setAttribute("width", "200%");
  filter.setAttribute("height", "200%");
  const blur = document.createElementNS(ns, "feGaussianBlur");
  blur.setAttribute("stdDeviation", "2");
  blur.setAttribute("result", "glow");
  filter.appendChild(blur);
  const merge = document.createElementNS(ns, "feMerge");
  const mn1 = document.createElementNS(ns, "feMergeNode");
  mn1.setAttribute("in", "glow");
  const mn2 = document.createElementNS(ns, "feMergeNode");
  mn2.setAttribute("in", "SourceGraphic");
  merge.appendChild(mn1);
  merge.appendChild(mn2);
  filter.appendChild(merge);
  defs.appendChild(filter);
  svg.appendChild(defs);

  for(const entry of slotEntries){
    const pos = STATE.bonePositions[entry.slot];
    if(!pos) continue;

    const boneX = pos.x * FRAME_W;
    const boneY = pos.y * FRAME_H;

    const slotCenterX = entry.finalX + halfSlot;
    const slotCenterY = entry.finalY + halfSlot;

    const dx = boneX - slotCenterX;
    const dy = boneY - slotCenterY;
    const dist = Math.sqrt(dx * dx + dy * dy) || 1;
    const edgeX = slotCenterX + (dx / dist) * halfSlot;
    const edgeY = slotCenterY + (dy / dist) * halfSlot;

    if(dist < halfSlot + 5) continue;

    const nx = -dy / dist;
    const ny = dx / dist;

    const lineLen = dist - halfSlot;
    const wave = Math.min(lineLen * 0.18, 50);

    const t1 = 0.33;
    const t2 = 0.66;
    const cp1x = edgeX + dx * t1 + nx * wave;
    const cp1y = edgeY + dy * t1 + ny * wave;
    const cp2x = edgeX + dx * t2 - nx * wave;
    const cp2y = edgeY + dy * t2 - ny * wave;

    const d = `M ${edgeX} ${edgeY} C ${cp1x} ${cp1y}, ${cp2x} ${cp2y}, ${boneX} ${boneY}`;

    const path = document.createElementNS(ns, "path");
    path.setAttribute("d", d);
    path.setAttribute("fill", "none");
    path.setAttribute("stroke", "#6B1C1C");
    path.setAttribute("stroke-width", "2.5");
    path.setAttribute("stroke-linecap", "round");
    path.setAttribute("filter", "url(#bone-line-glow)");
    svg.appendChild(path);

    const circle = document.createElementNS(ns, "circle");
    circle.setAttribute("cx", boneX);
    circle.setAttribute("cy", boneY);
    circle.setAttribute("r", "3");
    circle.setAttribute("fill", "#6B1C1C");
    circle.setAttribute("filter", "url(#bone-line-glow)");
    svg.appendChild(circle);
  }
}

function renderHud(){
  const $hud = STATE.ui.$hud;
  const $bars = STATE.ui.$hudBars;
  if(!$hud || !$bars || $hud.length === 0 || $bars.length === 0) return;

  const eq = STATE.equipment || {};
  const slots = slotsCfg();
  const active = new Set();
  const container = $bars.get(0);

  for(const slot of slots){
    const ent = eq[slot];
    if(!ent || !ent.itemName) continue;

    active.add(slot);

    let row = RENDER.hudRows.get(slot);
    if(!row){
      const el = document.createElement("div");
      el.className = "cas-armour-hud-row";
      el.dataset.slot = slot;

      const top = document.createElement("div");
      top.className = "cas-armour-hud-top";

      const icon = document.createElement("img");
      icon.className = "cas-armour-hud-icon";
      icon.loading = "lazy";
      icon.decoding = "async";

      const text = document.createElement("div");
      text.className = "cas-armour-hud-text";

      const slotEl = document.createElement("div");
      slotEl.className = "cas-armour-hud-slot rdr-lino";

      const nameEl = document.createElement("div");
      nameEl.className = "cas-armour-hud-name hapna";

      text.appendChild(slotEl);
      text.appendChild(nameEl);

      const val = document.createElement("div");
      val.className = "cas-armour-hud-val rdr-lino";

      top.appendChild(icon);
      top.appendChild(text);
      top.appendChild(val);

      const bar = document.createElement("div");
      bar.className = "cas-armour-hud-bar";

      const fill = document.createElement("div");
      fill.className = "cas-armour-hud-fill";
      bar.appendChild(fill);

      el.appendChild(top);
      el.appendChild(bar);

      row = { el, icon, slotEl, nameEl, val, fill, last: {} };
      RENDER.hudRows.set(slot, row);

      container.appendChild(el);
    } else {
      container.appendChild(row.el);
    }

    const piece = pieceByItemName(ent.itemName);
    const slotLabel = SLOT_LABEL[slot] || safeStr(slot).toUpperCase();
    const nameLabel = (piece && piece.name) ? piece.name : (ent.itemName || slotLabel);

    const maxC = Number(ent.maxCondition ?? (piece && piece.maxCondition) ?? 0) || 0;
    const c = Number(ent.condition ?? 0) || 0;
    const ratio = (maxC > 0) ? Math.max(0, Math.min(1, c / maxC)) : 0;
    const pct = Math.round(ratio * 100);

    const fallbackIcon = (piece && piece.icon) ? piece.icon : "assets/testitem.png";
    const iconUrl = vorpItemIconUrl(ent.itemName);

    if(row.last.slotLabel !== slotLabel){
      row.slotEl.textContent = slotLabel;
      row.last.slotLabel = slotLabel;
    }
    if(row.last.nameLabel !== nameLabel){
      row.nameEl.textContent = nameLabel;
      row.last.nameLabel = nameLabel;
    }

    const valStr = `${c}/${maxC}`;
    if(row.last.valStr !== valStr){
      row.val.textContent = valStr;
      row.last.valStr = valStr;
    }

    if(row.last.pct !== pct){
      row.fill.style.width = `${pct}%`;
      row.last.pct = pct;
    }

    if(row.last.iconUrl !== iconUrl || row.last.fallbackIcon !== fallbackIcon){
      row.icon.onerror = null;
      row.icon.src = iconUrl;
      row.icon.onerror = function(){
        this.onerror = null;
        this.src = fallbackIcon;
      };
      row.last.iconUrl = iconUrl;
      row.last.fallbackIcon = fallbackIcon;
    }
  }

  for(const [slot, row] of RENDER.hudRows.entries()){
    if(!active.has(slot)){
      row.el.remove();
      RENDER.hudRows.delete(slot);
    }
  }

  if(RENDER.hudRows.size === 0){
    $hud.removeClass("is-active");
    return;
  }

  $hud.addClass("is-active");
}

function renderStats(){
    const $grid = STATE.ui.$statsGrid;
    if($grid.length === 0) return;

    const stats = STATE.stats || {};
    const keys = Object.keys(stats).filter(k => stats[k] !== 0 && stats[k] !== null && stats[k] !== undefined);
    if(keys.length === 0){
      $grid.html(`<div class="flex items-center justify-center w-full h-full"><div class="text-white rdr-lino text-md text-center">No active bonuses</div></div>`);
      return;
    }

    const html = keys
      .sort((a,b) => a.localeCompare(b))
      .map(k => {
        const label = STAT_LABEL[k] || k.toUpperCase();
        const raw = stats[k];
        const color = STAT_COLOR[k] || "#AD3838";
        const icon = STAT_ICON[k] || "";
        const statMax = STAT_BAR_MAX[k] || STAT_BAR_DEFAULT_MAX;
        const pct = Math.min(100, Math.max(0, (Math.abs(raw) / statMax) * 100));
        const valText = `${Math.abs(raw).toFixed(1)}`;

        return `
          <div class="flex items-center w-full">
            <div class="flex flex-col flex-1 min-w-0">
              <div class="flex justify-between items-center">
                <div class="text-white text-[13px] rdr-lino truncate">${escapeHtml(label)}</div>
                <div class="text-[13px] rdr-lino flex-shrink-0 text-white">${escapeHtml(valText)}</div>
              </div>
              <div class="cas-stat-bar w-full h-[2px] overflow-hidden" style="-webkit-mask-image:url('assets/musicdivider.png');mask-image:url('assets/musicdivider.png');-webkit-mask-size:100% 100%;mask-size:100% 100%;-webkit-mask-repeat:no-repeat;mask-repeat:no-repeat;background:rgba(255,255,255,0.35);">
              </div>
            </div>
          </div>
        `;
      }).join("");

    $grid.html(html);
  }

  function equippedCountForSet(setId){
    const set = setsCfg()[setId];
    if(!set || !set.pieces) return 0;
    const eq = STATE.equipment || {};
    const have = new Set(Object.values(eq).filter(x=>x && x.pieceId).map(x=>x.pieceId));
    let c = 0;
    for(const pid of set.pieces){
      if(have.has(pid)) c++;
    }
    return c;
  }

  function renderSetsList(){
    const $list = STATE.ui.$setsList;
    if(!$list || $list.length === 0) return;

    const sets = setsCfg();
    const entries = Object.entries(sets);
    if(entries.length === 0){
      $list.html(`<div class="text-[#7D5E46] rdr-lino">No sets configured.</div>`);
      return;
    }

    const html = entries.map(([setId, set]) => {
      const count = equippedCountForSet(setId);
      const total = (set.pieces || []).length;
      const isSel = STATE.selectedSetId === setId;
      const hasImage = !!(set.image);

      return `
        <div class="bg-[url(assets/setrowbg.png)] bgfull w-full h-[140px] min-h-[140px] flex justify-center items-center cas-set-row ${isSel ? "cas-set-row-active" : ""}"
             data-setid="${escapeHtml(setId)}">
          <div class="w-[85%] h-[80%] flex flex-col items-center justify-center">
            <h1 class="text-[#7D5E46] text-2xl rdr-lino">${escapeHtml(set.name || setId)}</h1>
            <img src="assets/bborder.png" decoding="async" class="w-full object-contain" alt="" />
            <div class="w-full flex justify-between items-center">
              <div class="flex flex-col">
                <h1 class="text-[#7D5E46] rdr-lino text-md">Pieces</h1>
                <div class="text-[#7D5E46] rdr-lino text-sm">${escapeHtml(count)}/${escapeHtml(total)}</div>
              </div>
              <div class="flex flex-col">
                <h1 class="text-[#7D5E46] rdr-lino text-md">Bonus</h1>
                <div class="text-[#7D5E46] rdr-lino text-sm">${escapeHtml(bestThresholdText(set, count))}</div>
              </div>
              <div class="flex flex-col">
                <h1 class="text-[#7D5E46] rdr-lino text-md">Passive</h1>
                <div class="text-[#7D5E46] rdr-lino text-sm">${escapeHtml(activePassiveText(set, count))}</div>
              </div>
            </div>
          </div>
        </div>
      `;
    }).join("");

    $list.html(html);
  }

  function bestThresholdText(set, count){
  const b = normalizeBonuses(set && set.bonuses);
  const thresholds = Object.keys(b).map(n=>parseInt(n,10)).filter(n=>Number.isFinite(n)).sort((a,b)=>a-b);
  let best = null;
  for(const t of thresholds){
    if(count >= t) best = t;
  }
  if(best === null) return "-";
  return `${best}-piece`;
}
  function activePassiveText(set, count){
  const b = normalizeBonuses(set && set.bonuses);
  const thresholds = Object.keys(b).map(n=>parseInt(n,10)).filter(n=>Number.isFinite(n)).sort((a,b)=>a-b);
  let best = null;
  for(const t of thresholds){
    if(count >= t) best = t;
  }
  if(best === null) return "-";
  return (b[String(best)] && b[String(best)].passive) ? "YES" : "NO";
}
  function renderSetDetails(setId){
    const $details = STATE.ui.$setDetails;
    const sets = setsCfg();
    const pcs = piecesCfg();
    if(!$details || $details.length === 0) return;

    $details.css({ opacity: 0 });
    requestAnimationFrame(() => $details.css({ transition: "opacity 160ms ease", opacity: 1 }));

    const set = sets[setId];
    if(!set){
      $details.html(`<div class="text-[#584B32] rdr-lino">Select a set.</div>`);
      return;
    }

    const count = equippedCountForSet(setId);
    const total = (set.pieces || []).length;

    const have = new Set(Object.values(STATE.equipment || {}).filter(x=>x && x.pieceId).map(x=>x.pieceId));

    const piecesHtml = (set.pieces || []).map(pid => {
      const p = pcs[pid];
      const name = (p && p.name) ? p.name : pid;
      const slot = (p && p.slot) ? p.slot : "";
      const ok = have.has(pid);
      return `
        <div class="flex justify-between items-center w-full">
          <div class="text-[#584B32] rdr-lino">${escapeHtml(name)} <span class="text-[#7D5E46] text-sm">(${escapeHtml(slot)})</span></div>
          <div class="text-[#584B32] rdr-lino">${ok ? "EQUIPPED" : ""}</div>
        </div>
      `;
    }).join("");

    const bonuses = normalizeBonuses(set.bonuses);
    const thresholds = Object.keys(bonuses).map(n=>parseInt(n,10)).filter(n=>Number.isFinite(n)).sort((a,b)=>a-b);

    const bonusHtml = thresholds.map(t => {
      const b = bonuses[String(t)];
      if(!b || typeof b !== "object") return "";
      const active = count >= t;
      const stats = (b && b.stats) ? b.stats : {};
      const statsRows = Object.entries(stats).filter(([k,v]) => v !== 0 && v !== null && v !== undefined)
        .map(([k,v]) => `<div class="flex justify-between"><div class="text-[#584B32] hapna">${escapeHtml(STAT_LABEL[k] || k.toUpperCase())}</div><div class="text-[#584B32] hapna">${escapeHtml(v)}</div></div>`)
        .join("");
      const passive = b.passive ? `<div class="text-[#584B32] hapna">Passive: ${escapeHtml(PASSIVE_LABEL[b.passive] || b.passive)}</div>` : "";
      return `
        <div class="w-full mb-3 p-2 rounded" style="border:1px solid rgba(79,67,43,0.35); background: rgba(255,255,255,0.10);">
          <div class="flex justify-between items-center">
            <div class="text-[#4F432B] rdr-lino text-xl">${escapeHtml(t)}-PIECE ${escapeHtml(b.name || "")}</div>
            <div class="text-[#4F432B] rdr-lino">${active ? "ACTIVE" : ""}</div>
          </div>
          ${b.description ? `<div class="text-[#584B32] rdr-lino text-sm mb-2">${escapeHtml(b.description)}</div>` : ""}
          <div class="flex flex-col gap-1">${statsRows || `<div class="text-[#584B32] hapna">No stats.</div>`}</div>
          ${passive}
        </div>
      `;
    }).join("");

    $details.html(`
      <div class="w-full flex flex-col items-center justify-center mb-3">
        <h1 class="rdr-lino text-2xl text-[#584B32]">${escapeHtml(set.name || setId)} <span class="text-sm">(${escapeHtml(count)}/${escapeHtml(total)})</span></h1>
        ${set.description ? `<p class="rdr-lino text-md text-[#584B32] text-center">${escapeHtml(set.description)}</p>` : ""}
      </div>

      <div class="w-full mb-3">
        <h2 class="rdr-lino text-xl text-[#584B32] mb-2">Pieces</h2>
        <div class="flex flex-col gap-1">${piecesHtml || `<div class="text-[#584B32] rdr-lino">No pieces.</div>`}</div>
      </div>

      <div class="w-full">
        <h2 class="rdr-lino text-xl text-[#584B32] mb-2">Bonuses</h2>
        ${bonusHtml || `<div class="text-[#584B32] rdr-lino">No bonuses.</div>`}
      </div>
    `);
  }

  function bindInventoryDroppable(){
    const $inv = $("#player-inventory");
    if(!$inv.length) return;
    try { $inv.droppable("destroy"); } catch(e){}

    $inv.droppable({
      accept: ".cas-eq-item",
      tolerance: "pointer",
      over: function(){
        $(this).css("outline", "2px solid rgba(217,175,107,0.45)");
      },
      out: function(){
        $(this).css("outline", "none");
      },
      drop: function(event, ui){
        $(this).css("outline", "none");
        const $it = $(ui.draggable);
        const slot = $it.data("slot");
        if(slot){
          postNui("cas_armour:unequip", { slot: slot });
        }
      }
    });
  }

  function bindUI(){
    $(document).on("keydown", function(e){
      if(e.key === "Escape" && STATE.open){
        closeUI();
      }
    });

    $(document).on("input", "#cas-search", function(){
      STATE.query = $(this).val() || "";
      renderInventory();
    });

    $(document).on("click", ".cas-weight-filter", function(){
      $(".cas-weight-filter").removeClass("active");
      $(this).addClass("active");
      STATE.filterWeight = $(this).data("weight") || "all";
      renderInventory();
    });

    $(document).on("click", ".cas-sets-button", function(){
      showSets();
    });

    $(document).on("click", ".cas-slot-circle", function(e){
      e.stopPropagation();
      const slot = $(this).data("slot");
      if(!slot) return;

      if(STATE.focusedSlot === slot){
        STATE.focusedSlot = null;
        postNui("slotReset", {});
      } else {
        STATE.focusedSlot = slot;
        postNui("slotFocus", { slot: slot });
      }
    });

    $(document).on("click", ".cas-inv-item, .cas-eq-item", function(e){
      e.stopPropagation();
      const $it = $(this);
      setSelectedPanelFor($it.data("itemname"), decodeMeta($it.data("meta")));
    });

    $(document).on("click", function(e){
      if(!STATE.open) return;
      if(STATE.dragging) return;
      const $t = $(e.target);
      if($t.closest(".cas-inv-item, .cas-eq-item").length) return;
      if($t.closest("#cas-selected").length) return;
      if($t.closest("input, textarea").length) return;
      if($t.closest("#armor-ui").length){
        clearSelectedPanel();
        if(STATE.focusedSlot){
          STATE.focusedSlot = null;
          postNui("slotReset", {});
        }
      }
    });

    $(document).on("click", "#cas-close-sets", function(){
      showArmor();
    });

    $(document).on("click", ".cas-set-row", function(){
      const setId = $(this).data("setid");
      STATE.selectedSetId = setId;
      $(".cas-set-row").removeClass("cas-set-row-active");
      $(this).addClass("cas-set-row-active");
      renderSetDetails(setId);
    });
  }

  function applyState(payload){
  const p = payload || {};

  if(p.config) STATE.config = p.config;
  if(p.equipment) STATE.equipment = p.equipment;

  if(Array.isArray(p.inventory)){
    STATE.inventory = p.inventory;
    preloadInventoryIcons(STATE.inventory);
  }

  if(p.stats) STATE.stats = p.stats;
  if(Array.isArray(p.activeSetBonuses)) STATE.activeSetBonuses = p.activeSetBonuses;
  if(Array.isArray(p.activePassives)) STATE.activePassives = p.activePassives;

  markHudDirty();
  if(STATE.open){
    markMainDirty();
  }
}

  function cacheUI(){
    STATE.ui.$armorUI = $("#armor-ui");
    STATE.ui.$setsUI = $("#sets-ui");
    STATE.ui.$invGrid = $("#cas-inv-grid");
    STATE.ui.$floatingSlots = $("#cas-floating-slots");
    STATE.ui.$boneLines = $("#cas-bone-lines");
    STATE.ui.$statsGrid = $("#cas-stats-grid");
    STATE.ui.$selected = $("#cas-selected");
    STATE.ui.$selectedIcon = $("#cas-selected-icon");
    STATE.ui.$selectedSlot = $("#cas-selected-slot");
    STATE.ui.$selectedStats = $("#cas-selected-stats");
    STATE.ui.$setsList = $("#cas-sets-list");
    STATE.ui.$setDetails = $("#cas-set-details");
    STATE.ui.$hud = $("#cas-armour-hud");
    STATE.ui.$hudBars = $("#cas-armour-hud-bars");
  }

  window.addEventListener("message", function(event){
    const data = event.data;
    if(!data) return;

    if(data.action === "cas_armour:open"){
      openUI();
      return;
    }
    if(data.action === "cas_armour:close"){
      closeUI();
      return;
    }
    if(data.action === "cas_armour:setState"){
      applyState(data.payload || {});
      return;
    }
    if(data.action === "cas_armour:bonePositions"){
      STATE.bonePositions = data.positions;
      positionFloatingSlots();
      return;
    }
    if(data.action === "cas_armour:ping"){
      postNui("cas_armour:nuiReady", {});
      return;
    }
  });

  $(document).ready(function(){
    cacheUI();
    bindUI();
    bindInventoryDroppable();

    $("body").removeClass("cas-ui-open cas-stage");
    STATE.ui.$armorUI.removeClass("is-active");
    STATE.ui.$setsUI.removeClass("is-active");
    clearSelectedPanel();
    markHudDirty();

    setTimeout(() => { preloadCoreAssets(); }, 50);

    postNui("cas_armour:nuiReady", {});
  });

})();
