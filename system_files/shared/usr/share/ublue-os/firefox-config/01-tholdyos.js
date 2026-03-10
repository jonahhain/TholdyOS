// Firefox Defaults

// Hardware acceleration
pref("gfx.webrender.all", true);
pref("media.hardware-video-decoding.force-enabled", true);

// Disable crash report auto-submission
lockPref("browser.tabs.crashReporting.sendReport", false);
lockPref("browser.crashReports.unsubmittedCheck.autoSubmit2", false);

// Disable welcome pages and UI tour
pref("browser.aboutwelcome.enabled", false);
pref("startup.homepage_welcome_url", "");
pref("startup.homepage_welcome_url.additional", "");
pref("startup.homepage_override_url", "");
pref("startup.homepage_override.mstone", "ignore");
pref("browser.uitour.enabled", false);
pref("browser.messaging-system.whatsNewPanel.enabled", false);

// Suppress notification bars
pref("datareporting.policy.dataSubmissionPolicyBypassNotification", true);
pref("browser.rights.3.shown", true);

// Disable default browser check
pref("browser.shell.checkDefaultBrowser", false);

// Disable sponsored content on new tab
lockPref("browser.newtabpage.activity-stream.showSponsored", false);
lockPref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
lockPref("browser.newtabpage.activity-stream.default.sites", "");

// Disable extension and feature recommendations
lockPref("extensions.getAddons.showPane", false);
lockPref("extensions.htmlaboutaddons.recommendations.enabled", false);
lockPref("browser.discovery.enabled", false);
