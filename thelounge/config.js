"use strict";

module.exports = {
  public: true,
  lockNetwork: true,
  host: "0.0.0.0",
  port: 9000,
  defaults: {
    name: "offgrid-irc",
    host: "offgrid-tools-inspircd",
    port: 6667,
    tls: false,
    password: "",
    nick: "guest-%i", // %i becomes a random 4-digit number
    username: "guest",
    realname: "Offgrid User",
    join: "#general",
  },
};
