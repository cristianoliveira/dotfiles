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
//  brew install --cask finicky
//
//  see more in https://github.com/johnste/finicky

let timenow = new Date();

let isWorkingHours = (timenow.getHours() >= 9 && timenow.getHours() <= 18);

module.exports = {
  handlers: [
    {
      // Open work related urls open in Google Chrome
      match: [
        /meet\.google/,
        /atlassian.net/,
        /ngrok-free/,
        /tuple/,
        /figma/,
        /smartling/,
        /sentry.io/,
        /expo.dev/,
        /mail.google/,
        /github\.com/,
        /mixpanel\.com/,
        /miro\.com/,
        /segment\.com/,
        /sanity.studio/,
      ],
      browser: {
        name: "Google Chrome",
      }
    },
    {
      // Open code related urls in Google Chrome Canary
      match: [
        /localhost/,
        /local.gd/,
      ],
      browser: "Google Chrome Canary"
    },
  ].filter(() => isWorkingHours),

  // Any other urls open in Brave Browser
  defaultBrowser: "Brave Browser",
};
