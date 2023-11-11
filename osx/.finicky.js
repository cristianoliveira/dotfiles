// For OSX
//
// Make sure to open a given url in a specific browser
//
// What problem does it solve?
//
//   When someone share a link in Slack, it opens in a random browser,
//   it doesn't even respect the default browser setting in OSX --rage noises--
//
// Installing:
//
//  brew install finicky
//
//  see more in https://github.com/johnste/finicky
module.exports = {
  handlers: [
    {
      // Open work related urls open in Google Chrome
      match: /(sumup|sam-app|meet\.google)/,
      browser: "Google Chrome"
    },
    {
      // Open code related urls in Google Chrome Canary
      match: /localhost/,
      browser: "Google Chrome Canary"
    },
  ],

  // Any other urls open in Brave Browser
  defaultBrowser: "Brave Browser",
};
