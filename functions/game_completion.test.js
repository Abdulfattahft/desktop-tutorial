const assert = require("node:assert/strict");
const { _test } = require("./game_completion.js");

assert.equal(_test.levelForPoints(0), 1);
assert.equal(_test.levelForPoints(99), 1);
assert.equal(_test.levelForPoints(100), 2);
assert.equal(_test.levelForPoints(9000), 10);

const sameDay = _test.nextStreak(
  4,
  new Date("2026-08-03T10:00:00Z"),
  new Date("2026-08-03T20:00:00Z")
);
assert.equal(sameDay, 4);

const nextDay = _test.nextStreak(
  4,
  new Date("2026-08-02T10:00:00Z"),
  new Date("2026-08-03T10:00:00Z")
);
assert.equal(nextDay, 5);

const reset = _test.nextStreak(
  4,
  new Date("2026-07-30T10:00:00Z"),
  new Date("2026-08-03T10:00:00Z")
);
assert.equal(reset, 1);

assert.equal(
  _test.dateKeyInRiyadh(new Date("2026-08-02T22:30:00Z")),
  "2026-08-03"
);

console.log("game_completion tests passed");
