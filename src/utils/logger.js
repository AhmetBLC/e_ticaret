const { logLevel: configuredLevel, nodeEnv } = require("../config/env");

const LEVELS = { debug: 10, info: 20, warn: 30, error: 40, silent: 100 };

function levelValue(name) {
  const n = LEVELS[String(name).toLowerCase()];
  return n ?? LEVELS.info;
}

const activeLevel = levelValue(configuredLevel);

function shouldLog(level) {
  return activeLevel <= level;
}

function formatLine(level, event, meta) {
  const ts = new Date().toISOString();
  if (meta != null && typeof meta === "object") {
    return `[${ts}] [${level.toUpperCase()}] ${event} ${JSON.stringify(meta)}`;
  }
  return `[${ts}] [${level.toUpperCase()}] ${event}`;
}

function debug(event, meta) {
  if (!shouldLog(LEVELS.debug)) {
    return;
  }
  console.debug(formatLine("debug", event, meta));
}

function info(event, meta) {
  if (!shouldLog(LEVELS.info)) {
    return;
  }
  console.info(formatLine("info", event, meta));
}

function warn(event, meta) {
  if (!shouldLog(LEVELS.warn)) {
    return;
  }
  console.warn(formatLine("warn", event, meta));
}

function error(event, meta) {
  if (!shouldLog(LEVELS.error)) {
    return;
  }
  console.error(formatLine("error", event, meta));
}

/**
 * Full error object for the console (stack in development).
 * @param {string} label
 * @param {Error} err
 */
function errorWithStack(label, err) {
  console.error(`[ERROR] ${label}`);
  if (nodeEnv !== "production" && err && err.stack) {
    console.error(err.stack);
  } else if (err && err.message) {
    console.error(err.message);
  }
}

module.exports = {
  debug,
  info,
  warn,
  error,
  errorWithStack,
  LEVELS,
  shouldLog,
};
