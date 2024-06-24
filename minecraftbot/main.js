import dotenv from "dotenv"

dotenv.config();

import axios from "axios";
import mineflayer from 'mineflayer';
import { mineflayer as mineflayerViewer } from "prismarine-viewer";
import pkg from 'mineflayer-pathfinder';
const { pathfinder, Movements, goals } = pkg;
const { GoalNear, GoalFollow } = goals;
import { plugin, plugin as pvp } from 'mineflayer-pvp';
import { plugin as autoeat } from 'mineflayer-auto-eat';
import armorManager from 'mineflayer-armor-manager';
import * as fs from 'fs';
import { OpenAIClient, AzureKeyCredential } from "@azure/openai";
import { DaprClient, DaprServer, HttpMethod, CommunicationProtocolEnum } from "@dapr/dapr";

const daprHost = "127.0.0.1"; // Dapr Sidecar Host
const daprPort = "3500";

class Bot {
  // Constructor
  constructor(account, useGPT = true) {
    // Initialize the bot
    this.useGPT = useGPT;
    this.isReady = false;
    this.currentTaskPriority = 4;
    this.currentTask = null;
    this.memory = {
      targetUsername: '',
    };
    this.firstSpawn = true;
    this.chatHistory = [];
    this.state = null;
    this.nearbyPlayers = [];
    this.ticks = 0;
    this.votes = {
      terraform: 0,
      iot: 0,
      bot: 0,
      plugin: 0,
      blazor: 0,
      dapr: 0
    }
    this.initBot(account);
    let endpoint = process.env.AZURE_OPENAI_ENDPOINT;
    let key = process.env.AZURE_OPENAI_API_KEY;
    this.client = new OpenAIClient(
      endpoint,
      new AzureKeyCredential(key)
    );
  }

  // Init bot instance
  initBot(account) {
    this.bot = mineflayer.createBot({
      host: process.env.MINECRAFT_HOST,
      username: account,
      logErrors: false,
      auth: 'offline',
    });

    this.loadPlugins();

    this.debugLogInterval();

    this.initEvents();
  }

  initEvents() {
    this.bot.once('spawn', () => {
      this.initMovementConfig();
      this.initAutoEatConfig();
      this.bot.armorManager.equipAll();
      this.initAI();
      this.initDapr();

      mineflayerViewer(this.bot, { port: 8080 });
      this.path = [this.bot.entity.position.clone()];

      this.isReady = true;
      this.talk('Spawned');
    });

    this.bot.on('chat', (user, msg) => {
      this.chatHandler(user, msg);
    });

    this.bot.on('physicsTick', () => {
      this.lookAtNearestEntity();
      this.physicsTickTaskHandler();
      this.rangedSelfDefense();
      this.nearbyPlayerHandler();
    });

    // on being hurt
    this.bot.on('entityHurt', (entity) => {
      console.log(entity);
      if (entity === this.bot.entity) {
        // this.talk(`My health: ${this.bot.health}`);
        // this.talk(`My hunger: ${this.bot.food}`);
      }
    });

    this.bot.on('health', () => {
      // this.talk(`My health: ${this.bot.health}`);
      // this.talk(`My hunger: ${this.bot.food}`);
    });

    this.bot.on('death', () => {
      this.firstSpawn = false;
      this.currentTask = null;
      this.currentTaskPriority = 5;
      this.memory.targetUsername = '';
    });

    this.bot.on('spawn', () => {
      if (!this.firstSpawn) {
        this.talk('Hola dotNET2024...');
      }
    });

    this.bot.on('rain', () => {
      this.talk('It is raining..., let me fix that for you');
      this.talk('/weather clear');
    });

    this.bot.on('kicked', console.log);

    this.bot.on('error', console.log);

    this.bot.on('move', () => {
      if (!this.isReady) return;

      if (this.path[this.path.length - 1].distanceTo(this.bot.entity.position) > 1) {
        this.path.push(this.bot.entity.position.clone())
        this.bot.viewer.drawLine('path', this.path)
      }
    })
  }

  initMovementConfig() {
    const customMoves = new Movements(this.bot);
    customMoves.canDig = false;
    customMoves.allow1by1towers = false;
    customMoves.scafoldingBlocks = [];
    customMoves.allowParkour = true;
    this.bot.pathfinder.setMovements(customMoves);
    this.bot.pvp.movements = customMoves;
  }

  initAutoEatConfig() {
    this.bot.autoEat.options.startAt = 19;
  }

  loadPlugins() {
    this.bot.loadPlugin(pathfinder);
    this.bot.loadPlugin(pvp);
    this.bot.loadPlugin(autoeat);
    this.bot.loadPlugin(armorManager);
  }

  talk(message) {
    this.bot.chat(message);
    if (this.daprClient) {
      this.daprClient.pubsub.publish("eventhubs", "chat", { message: this.bot.username + ": " + message });
    }
  }

  chatHandler(user, msg) {
    if (user === this.bot.username) return;
    console.log('user', user);
    console.log('msg', msg);

    this.daprClient.pubsub.publish("eventhubs", "chat", { message: user + ": " + msg });

    switch (msg.toLowerCase()) {
      case 'come':
      case 'follow me':
      case 'follow': {
        this.followPlayer(user);
        break;
      }

      case 'attack me': {
        this.attackPlayer(user);
        break;
      }

      case 'attack all': {
        this.attackAllPlayers();
        break;
      }

      case 'stop': {
        this.stopFollowing();
        break;
      }

      case 'stop attack': {
        this.stopAttacking();
        break;
      }

      case 'defend': {
        this.defend();
        break;
      }

      case 'day': {
        this.talk('/time set day');
        break;
      }

      case 'clear': {
        this.talk('/weather clear');
        break;
      }

      case 'status': {
        this.getBotStatus();
        break;
      }

      case "weather":
        const url = process.env.WEATHER_API_URL;
        const me = this

        this.daprClient.invoker.invoke(url, "/api/plugins/forecast?location=Madrid", HttpMethod.GET).then((res) => {
          console.log(res);
          me.talk(res.response);
        });
        break;

      case "votes":
        const msg = `What are the top 3 options, given that the poll result was: Terraform: ${this.votes.terraform}, IoT: ${this.votes.iot}, Bot: ${this.votes.bot}, Plugin: ${this.votes.plugin}, Blazor: ${this.votes.blazor}, Dapr: ${this.votes.dapr}`;
        this.chatWithAI(user, msg);
        break;

      case 'light':
        console.log(`light action`);
        this.iotLights("Turn on a blue light");
        break;
    }

    if (msg.toLowerCase().startsWith("?")) {
      if (msg.toLowerCase().includes('teleported')) return;
      this.chatWithAI(user, msg.substring(1));
    }
  }

  stopFollowing() {
    this.currentTask = null;
    this.currentTaskPriority = 5;
    this.memory.targetUsername = '';
    this.bot.pathfinder.stop();
    this.talk('I stopped following you.');
  }

  stopAttacking() {
    this.bot.pvp.stop();
    this.bot.pvp.forceStop();
    this.talk('I stopped attacking.');
  }

  lookAtNearestEntity() {
    const playerEntity = this.bot.nearestEntity((entity) => {
      return entity.type === 'player' || entity.type === 'mob';
    });

    if (!playerEntity) return;

    const pos = playerEntity.position.offset(0, playerEntity.height, 0);
    this.bot.lookAt(pos);
  }

  debugLogInterval() {
    setInterval(() => {
      // console.log(this);
    }, 5000);
  }

  nearbyPlayerHandler() {
    this.ticks++;
    if (this.ticks % 20 !== 0) return; // every 20 ticks (1 second)
    // all the players within 10 blocks
    const currentNearbyPlayers = Object.keys(this.bot.players)
      .filter((username) => {
        if (username === this.bot.username) return false;
        const player = this.bot.players[username];
        if (!player.entity) return false;
        return (
          player.entity.position.distanceTo(this.bot.entity.position) <= 20
        );
      })
      .sort();
    if (
      this.nearbyPlayers.toString() !== currentNearbyPlayers.sort().toString()
    ) {
      const oldPlayersSet = new Set(this.nearbyPlayers);
      const newPlayersSrt = new Set(currentNearbyPlayers);
      const newPlayers = currentNearbyPlayers.filter(
        (player) => !oldPlayersSet.has(player)
      );
      const leftPlayers = this.nearbyPlayers.filter(
        (player) => !newPlayersSrt.has(player)
      );
      this.nearbyPlayers = currentNearbyPlayers;
      if (newPlayers.length) {
        // this.chatWithAI(
        // 	'Admin',
        // 	'Sakanabot, this is a system message: the following players are nearby: ' +
        // 		newPlayers.join(', ') +
        // 		'. Please greet them.'
        // );

        this.talk(`Hey!, ${newPlayers.join(', ')} !`);
      }
      if (leftPlayers.length) {
        // this.chatWithAI(
        // 	'Admin',
        // 	'Sakanabot, this is a system message: the following players just left your nearby area (but they are still in the game): ' +
        // 		leftPlayers.join(', ') +
        // 		'. Please say goodbye to them.'
        // );

        this.talk(`Bye, ${leftPlayers.join(', ')} !`);
      }
    }
    console.log('nearbyPlayers', this.nearbyPlayers);
  }

  physicsTickTaskHandler() {
    switch (this.currentTask) {
      case 'follow': {
        // go to the player's position within 2 blocks
        const playerEntity =
          this.bot.players[this.memory.targetUsername]?.entity;
        if (!playerEntity) {
          this.talk("I don't see you !");
          this.currentTask = null;
          return;
        }
        // if there is any hostile mob 5 blocks around the player entity, attack it instead.
        const hostileEntity = this.bot.nearestEntity((entity) => {
          return (
            entity.kind === 'Hostile mobs' &&
            entity.position.distanceTo(playerEntity.position) <= 5
          );
        });
        if (hostileEntity) {
          this.attackHandler(hostileEntity);
        } else {
          this.bot.pathfinder.setGoal(
            new GoalNear(
              playerEntity.position.x,
              playerEntity.position.y,
              playerEntity.position.z,
              2
            )
          );
        }
        break;
      }
      case 'attack': {
        if (
          !this.memory.targetUsername ||
          !this.bot.players[this.memory.targetUsername] ||
          !this.bot.players[this.memory.targetUsername]?.entity
        ) {
          this.talk('I lost my target.');
          this.currentTask = null;
          return;
        }
        this.attackPlayer(this.memory.targetUsername);
        break;
      }
      case 'defend': {
        this.defend();
        break;
      }

      case 'attack all': {
        // attack nearest player
        const playerEntity = this.bot.nearestEntity((entity) => {
          return entity.type === 'player';
        });
        if (!playerEntity) return;
        this.attackHandler(playerEntity);
      }
      default:
        break;
    }
  }

  iotLights(prompt) {
    console.log(`DEBUG: light command, prompt: ${prompt}`);
    this.daprClient.pubsub.publish("eventhubs", "bot-commands", { UserPrompt: prompt, Taco: false })
  }

  followPlayer(username) {
    this.currentTaskPriority = 0;
    this.currentTask = 'follow';
    this.memory.targetUsername = username;
    return;
  }

  attackPlayer(username) {
    const playerEntity = this.bot.players[username]?.entity;
    if (!playerEntity) {
      return;
    }
    this.attackHandler(playerEntity);
  }

  attackAllPlayers() {
    this.currentTaskPriority = 1;
    this.currentTask = 'attack all';
    this.memory.targetUsername = 'all';
    this.talk('I will attack all players nearby.');
  }

  defend() {
    // attack nearby hostile mobs
    setTimeout(() => {
      const hostileEntity = this.bot.nearestEntity((entity) => {
        console.log('entity', entity);
        return entity.kind === 'Hostile mobs';
      });
      console.log('hostileEntity', hostileEntity);
      if (!hostileEntity) return;
      this.attackHandler(hostileEntity);

      this.defend();
    }, 2000);
  }

  rangedSelfDefense() {
    // const PRIORITY = 2;
    // if (this.currentTdatskPriority < PRIORITY) return;
    // this.currentTaskPriority = PRIORITY;
    const hostileEntity = this.bot.nearestEntity((entity) => {
      return (
        entity.kind === 'Hostile mobs' &&
        entity.position.distanceTo(this.bot.entity.position) <= 5
      );
    });
    if (hostileEntity) {
      this.attackHandler(hostileEntity);
    }
  }

  async initAI() {
    if (!this.useGPT) return;
    console.log('initializing GPT config...');

    // Read the file synchronously
    const prompt = fs.readFileSync('prompt.txt', 'utf-8');

    this.chatHistory.push({ role: 'system', content: prompt });
    this.chatHistory.push({
      role: 'user',
      content: JSON.stringify({
        username: 'Admin',
        query:
          'Greet all the developers that are watching you today.',
        timestamp: Date.now(),
      }),
    });

    const resContent = await this.requestGPT();
    this.talk(resContent.comment);
    console.log('[initAI] initial bot response: ', resContent);
  }

  async requestGPT() {
    if (!this.useGPT) return;

    const completition = await this.client.getChatCompletions(
      "gpt-35-turbo",
      this.chatHistory,
      { maxTokens: 128 }
    );

    const chatMessage = completition.choices[completition.choices.length - 1].message;
    this.chatHistory.push(chatMessage);

    console.log(chatMessage.content);
    const content = JSON.parse(chatMessage.content);

    // save init chat history to file
    fs.writeFileSync(
      'chatHistory.json',
      JSON.stringify(this.chatHistory, null, 2),
      'utf8'
    );

    return content;
  }

  async chatWithAI(username, message) {
    if (!this.useGPT) return;
    console.log('[chatWithAI] request', username, message);
    const request = {
      username,
      query: message,
      timestamp: Date.now(),
      botStatus: this.getBotStatus(),
    };

    this.chatHistory.push({
      role: 'user',
      content: JSON.stringify(request),
    });

    const res = await this.requestGPT();

    const {
      action: responseAction,
      username: responseUsername,
      target: responseTarget,
      comment: responseComment,
    } = res;

    console.log('[chatWithAI] bot response:', responseComment);
    if (responseAction !== 'light') this.talk(responseComment);

    switch (responseAction) {
      case 'chat': {
        console.log(`DEBUG: chat command, target: ${responseTarget}`);
        // TODO: get bot's status and sent to chat completion for reference.
        break;
      }
      case 'sleep': {
        this.currentTask = 'sleep';
        console.log(`DEBUG: sleep command, target: ${responseTarget}`);
        break;
      }
      case 'goTo': {
        this.currentTask = 'goTo';
        console.log(`DEBUG: goTo command, target: ${responseTarget}`);
        break;
      }
      case 'follow': {
        console.log(`DEBUG: follow command, target: ${responseTarget}`);
        this.followPlayer(responseTarget);
        break;
      }
      case 'attack': {
        this.currentTask = 'attack';
        this.memory.targetUsername = responseTarget;
        console.log(`DEBUG: attack command, target: ${responseTarget}`);
        break;
      }
      case 'guard': {
        this.currentTask = 'guard';
        console.log(`DEBUG: guard command, target: ${responseTarget}`);
        break;
      }
      case 'light': {
        this.talk('Wait a moment...')
        this.iotLights(message);
        console.log(`DEBUG: light command, target: ${responseTarget}`);
        break;
      }
      case 'taco': {
        this.daprClient.pubsub.publish("eventhubs", "bot-commands", { UserPrompt: message, Taco: true })
        console.log(`DEBUG: taco command, target: ${responseTarget}`);
        break;
      }
      case 'error': {
        console.log(`DEBUG: error command, target: ${responseTarget}`);
        break;
      }
      default:
        console.log(`DEBUG: none command, target: ${responseTarget}`);
        break;
    }
  }

  getBotStatus() {
    if (!this.isReady) return;
    // get the bot's status including health, food, position, items, etc
    const botStatus = {
      health: this.bot.health.toFixed(2),
      food: this.bot.food,
      level: this.bot.experience.level,
      currentTask: this.currentTask,
    };

    console.log('[getBotStatus] botStatus:', botStatus);
    return botStatus;
  }

  attackHandler(targetEntity) {
    // equip the best weapon
    const weapons = this.bot.inventory
      .items()
      .filter(
        (item) => item.name.includes('sword') || item.name.includes('axe')
      );

    if (weapons.length) {
      weapons.sort((a, b) => b.maxDurability - a.maxDurability);
      this.bot.equip(weapons[0], 'hand');
    }

    this.bot.pvp.attack(targetEntity);
  }

  async initDapr() {
    this.daprClient = new DaprClient({
      daprHost,
      daprPort,
      communicationProtocol: CommunicationProtocolEnum.HTTP
    });

    this.daprServer = new DaprServer({
      serverHost: daprHost,
      serverPort: "80",
      communicationProtocol: CommunicationProtocolEnum.HTTP,
      clientOptions: {
        daprHost,
        daprPort,
      },
    });

    await this.daprServer.pubsub.subscribe("eventhubs", "iot_responses", async (response) => {
      console.log(`IoT sent: ${response}`)
      const res = JSON.parse(response);
      this.talk(res.IotResponse);
    });

    await this.daprServer.pubsub.subscribe("eventhubs", "votes", async (response) => {
      console.log(`Vote received`);
      if (response["Terraform"]) {
        this.votes.terraform++;
      }
      if (response["IoT"]) {
        this.votes.iot++;
      }
      if (response["Minecraft"]) {
        this.votes.bot++;
      }
      if (response["OpenAI"]) {
        this.votes.plugin++;
      }
      if (response["Blazor"]) {
        this.votes.blazor++;
      }
      if (response["Dapr"]) {
        this.votes.dapr++;
      }
    });

    this.daprServer.start();
  }
}

const bot = new Bot(
  process.env.MINECRAFT_BOT_NAME,
  true
);
