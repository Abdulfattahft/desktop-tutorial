const coreFunctions = require("./index.js");
const { finishGame } = require("./game_completion.js");

module.exports = {
  ...coreFunctions,
  finishGame,
};
