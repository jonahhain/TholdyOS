// Firefox Defaults

// Hardware acceleration
pref("gfx.webrender.all", true);
pref("media.hardware-video-decoding.force-enabled", true);

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
