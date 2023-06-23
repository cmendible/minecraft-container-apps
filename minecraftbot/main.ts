const axios = require('axios');
// https://github.com/PrismarineJS/mineflayer
const mineflayer = require("mineflayer");
const { mineflayer: mineflayerViewer } = require("prismarine-viewer");
const { pathfinder, Movements } = require("mineflayer-pathfinder");
const { GoalNear, GoalBlock, GoalXZ, GoalY, GoalInvert, GoalFollow } = require("mineflayer-pathfinder").goals;

// Azure Open AI module
const { OpenAIClient, AzureKeyCredential } = require("@azure/openai");

const client = new OpenAIClient(
  process.env.AZURE_OPENAI_ENDPOINT,
  new AzureKeyCredential(process.env.AZURE_OPENAI_API_KEY)
);

const bot = mineflayer.createBot({
  host: process.env.MINECRAFT_HOST, // optional ('51.105.170.25')
  port: process.env.MINECRAFT_PORT, // optional (25565)
  username: process.env.MINECRAFT_BOT_NAME,
  //   password: 'minecraft',          // online-mode=true servers
  //   version: false                 // false corresponds to auto version detection (that's the default), put for example "1.8.8" if you need a specific version
});

bot.loadPlugin(pathfinder);

bot.once("spawn", () => {
  // Once we've spawn, it is safe to access mcData because we know the version
  const mcData = require("minecraft-data")(bot.version);

  // We create different movement generators for different type of activity
  const defaultMove = new Movements(bot, mcData);

  mineflayerViewer(bot, { port: 8181, firstPerson: true }); // port is the minecraft server port, if first person is false, you get a bird's-eye view

  bot.on("path_update", (r) => {
    const nodesPerTick = ((r.visitedNodes * 50) / r.time).toFixed(2);
    console.log(
      `I can get there in ${r.path.length
      } moves. Computation took ${r.time.toFixed(
        2
      )} ms (${nodesPerTick} nodes/tick).`
    );
  });

  bot.on("goal_reached", (goal) => {
    bot.chat("Here I am !");
  });

  bot.on("chat", async (username, message) => {
    if (username === bot.username) return;
    const target = bot.players[username] ? bot.players[username].entity : null;

    console.log(`message: ${message}`);

    switch (message) {
      case "come":
        console.log(`come action`);
        if (!target) {
          bot.chat("I don't see you !");
          return;
        }
        const p = target.position;

        bot.pathfinder.setMovements(defaultMove);
        bot.pathfinder.setGoal(new GoalNear(p.x, p.y, p.z, 1));
        break;
      case "follow":
        console.log(`follow action`);
        bot.pathfinder.setMovements(defaultMove);
        bot.pathfinder.setGoal(new GoalFollow(target, 3), true);
        // follow is a dynamic goal: setGoal(goal, dynamic=true)
        // when reached, the goal will stay active and will not
        // emit an event
        break;
      case "avoid":
        console.log(`avoid action`);
        bot.pathfinder.setMovements(defaultMove);
        bot.pathfinder.setGoal(new GoalInvert(new GoalFollow(target, 5)), true);
        break;
      case "stop":
        console.log(`stop action`);
        bot.pathfinder.setGoal(null);
        break;
      case "read temperature":
        console.log(`read temperature action`);
        bot.chat("Reading temperature for sensor 1...");
        axios
          .get("http://localhost:3500/v1.0/invoke/dapr-sensors-average/method/average/1", {
            responseType: "json",
          })
          .then(function (response) {
            let temp = response.data.temperature;
            console.log(temp);
            bot.chat("Temperature is " + temp + " degrees");
          });
        break;
      case "read items"
        console.log(`read items action`);
        sayItems(null);
      default:
        if (message.startsWith("?")) {
          console.log(`chatgpt action`);
          let prompt = message.replace("?", "");

          console.log(`prompt: ${prompt}`);

          const messages = [
            {
              role: "system",
              content: "You are a chearful assistant assistant.",
            },
            { role: "user", content: prompt },
          ];

          const events = await client.listChatCompletions(
            process.env.AZURE_OPENAI_DEPLOYMENT,
            messages,
            { maxTokens: 128 }
          );

          let completeAnswer = "";

          for await (const event of events) {
            for (const choice of event.choices) {
              console.log(choice.delta?.content);
              if (choice.delta?.content !== undefined) {
                completeAnswer += choice.delta?.content;
              }
            }
          }

          console.log(`completeAnswer: ${completeAnswer}`);
          bot.chat(completeAnswer); // If not the minecraft bot will think you are spamming!
        } else if (message.startsWith("goto")) {
          console.log(`goto action`);

          const cmd = message.split(" ");

          goTo(bot, cmd, defaultMove);
        }

        break;
    }
  });
});

function goTo(bot, cmd, defaultMove) {
  let x, y, z;

  switch (cmd.length) {
    case 4:
      // goto x y z
      x = parseInt(cmd[1], 10);
      y = parseInt(cmd[2], 10);
      z = parseInt(cmd[3], 10);

      bot.pathfinder.setMovements(defaultMove);
      bot.pathfinder.setGoal(new GoalBlock(x, y, z));

      break;
    case 3:
      // goto x z
      x = parseInt(cmd[1], 10);
      z = parseInt(cmd[2], 10);

      bot.pathfinder.setMovements(defaultMove);
      bot.pathfinder.setGoal(new GoalXZ(x, z));
      break;
    case 2:
      // goto y
      y = parseInt(cmd[1], 10);

      bot.pathfinder.setMovements(defaultMove);
      bot.pathfinder.setGoal(new GoalY(y));

      break;
  }
}

// Log errors and kick reasons:
bot.on("kicked", (reason, loggedIn) => console.log(reason, loggedIn));
bot.on("error", (err) => console.log(err));

var express = require("express");
var bodyParser = require("body-parser");

var app = express();

// parse application/cloudevents+json
app.use(bodyParser.json({ type: "application/cloudevents+json" }));

const port = 8080;

app.get("/dapr/subscribe", (req, res) => {
  res.json([
    {
      pubsubname: "messagebus",
      topic: "temperature",
      route: "temperature",
    },
    {
      pubsubname: "messagebus",
      topic: "tnt",
      route: "tnt",
    },
  ]);
});

app.post("/temperature", (req, res) => {
  try {
    let message = req.body.data;
    console.log(`Average: ${message.temperature}`);
    res.sendStatus(200);
  } catch (e) {
    console.log(e);
    res.sendStatus(500);
  }
});

app.post("/tnt", (req, res) => {
  try {
    let message = req.body.data;
    console.log(`tnt order received...`);
    bot.chat(`tnt order received...`);

    // Create TNT Block
    const tnt = bot.findBlock({ point: bot.entity.position, matching: "minecraft:tnt" });
    if (tnt == null) {
      return;
    }
    var Vec3 = require('vec3').Vec3;
    bot.placeBlock(tnt, new Vec3(0, -1, 0));

    // bot.chat(`Average: what?`);
    res.sendStatus(200);
  } catch (e) {
    console.log(e);
    res.sendStatus(500);
  }
});

app.listen(port, () => console.log(`minecraft bot listening on port ${port}`));

function itemByName (name) {
  const items = bot.inventory.items()
  if (bot.registry.isNewerOrEqualTo('1.9') && bot.inventory.slots[45]) items.push(bot.inventory.slots[45])
  return items.filter(item => item.name === name)[0]
}

function sayItems (items = null) {
  if (!items) {
    items = bot.inventory.items()
    if (bot.registry.isNewerOrEqualTo('1.9') && bot.inventory.slots[45]) items.push(bot.inventory.slots[45])
  }
  const output = items.map(itemToString).join(', ')
  if (output) {
    bot.chat(output)
  } else {
    bot.chat('empty')
  }
}

async function equipItem (name, destination) {
  const item = itemByName(name)
  if (item) {
    try {
      await bot.equip(item, destination)
      bot.chat(`equipped ${name}`)
    } catch (err) {
      bot.chat(`cannot equip ${name}: ${err.message}`)
    }
  } else {
    bot.chat(`I have no ${name}`)
  }
}

function itemToString (item) {
  if (item) {
    return `${item.name} x ${item.count}`
  } else {
    return '(nothing)'
  }
}
