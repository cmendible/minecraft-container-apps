var utils = require('utils');
exports.setsigntext = function (x, y, z, temp, energy) {
    var world = server.worlds.get(0);
    var block = world.getBlockAt(x, y, z);
    var state = block.state;
    if (state instanceof org.bukkit.block.Sign) {
        state.setLine(0, "Temperature:");
        state.setLine(1, temp);
        state.setLine(2, "E. Generator:");
        state.setLine(3, energy);
        state.update(true);
    }
};