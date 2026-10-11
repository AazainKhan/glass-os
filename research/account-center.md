# Account separation: Alexa vs Prime Video on one Fire OS 8 device

Static analysis only (no device access). Image: rom/work/extracted. Date 2026-10-10.

## Question
Can Alexa (com.amazon.vizzini + com.amazon.aria) and Prime Video (com.amazon.firebat) be signed into different Amazon accounts on one stick?

## Evidence
1. The real MAP is `com.amazon.imp` (priv-app), not `com.amazon.identity.auth.device.authorization`.
   - imp exposes `com.amazon.dcp.sso.*`: AccountAuthenticationService (it is the Android AccountAuthenticator), AccountSubAuthenticator, OAuthSubAuthenticatorService, SessionUserService, CustomerAttributeProvider, DeviceDataProvider, CORPFMChangeHandler.
   - The `...device.authorization` APK is only the Login-with-Amazon credential manager (AmazonCredentialManagerService, a MapInfoProvider).
   - Java API lives in framework `com.amazon.identity.auth.device.jar`. The strings in vizzini and aria show MAPAccountManager is bundled in them as an obfuscated client lib.
2. MAP is not strictly single-account. imp dex strings show:
   - Primary plus secondary accounts: "secondary account added/removed" broadcasts, `bootstrapSupportSecondaryAccounts`, `map_legacy_secondary_registration`, `map_panda_secondary_registration`, `registerDeviceToSecondaryCustomer`, KEY_ALLOW_ADDING_MULTIPLE_PRIMARY_ACCOUNT.
   - Child applications: SubAuthChildApplicationRegistrar, `registerChildApplication`, "is not a child application device type".
   - Isolation: static isolated mode, runtime isolated mode, Client_App_Driven_Runtime_Isolation, `clientDrivenSwitchAppToIsolatedMode`, "No account detected in isolated mode", "App needs isolation on devices". An isolated app keeps its own account apart from the device account.
   - Delegated accounts and actors (Amazon Household/Kids style): delegated OAuth tokens, `DelegatedAccountProfileIdMissing`, `NonWhitelistAppRegisterDelegatedAccount` (registration is whitelisted), actor tokens. Session users via `com.amazon.dcp.sso.property.sessionuser` and `com.amazon.android.os.MultipleProfileHelper`, with permission `com.amazon.permission.SET_PROFILE`.
3. Consumers. Their permissions are the device-credential type, not isolated-app registration.
   - vizzini, aria, profilepicker: `dcp.sso.permission.USE_DEVICE_CREDENTIALS`, `MULTIPLE_PROFILE_AWARE`, `MANAGE_DEVICE_AND_USER_DATA`, `EXPIRE_ACCESS_TOKEN`, `CUSTOMER_ATTRIBUTE_SERVICE`. These are 1P apps bound to the device (primary) account, with profile awareness inside it.
   - firebat in this image is only a 82 KB stub (`com.amazon.firebat-stub`). Manifest: USE_DEVICE_CREDENTIALS, CUSTOMER_ATTRIBUTE_SERVICE, account.changed. The real Prime Video APK is not in the image, so its isolation flags and client-driven isolation support are UNVERIFIED. They would need the installed APK (an adb pull, deferred).
   - The ottssocompanionapp (MapUtil, PKI/CSR utils) is the streaming-app SSO helper. It is a possible hook point and not analysed further.
4. Public info (thin, consumer-level, no MAP internals found):
   - Guiding Tech says Prime Video follows the Fire TV registered account, and changing it means deregistering the device: https://www.guidingtech.com/change-prime-video-account/
   - Profiles (up to 6 per account) are the only supported multi-person model. Searches for "MAP", "isolated mode" and "MultipleAccountManager" found nothing public.

## Verdict
PARTIALLY feasible. The platform layer (secondary accounts, child apps, isolation) can hold two identities. But Alexa (vizzini/aria) is a first-party system app tied to the device account, and Prime Video's behaviour is unverified. There is no supported UI to sign Prime Video into a second account. I could not statically prove that Prime Video can enter isolated mode or take a second account. Treat it as unproven until the real firebat APK is inspected.

## Options (ranked by cost vs. confidence)
| # | Option | Cost | Risks |
|---|--------|------|-------|
| A | Fire profiles (profilepicker/prism) plus Prime Video profiles in the one account | 0.5 d | Same account, so it does not meet the goal. Zero risk. |
| B | Check whether installed Prime Video has an isolated or standalone sign-in path (pull the APK, grep the manifest and strings for the isolation flags above; try the "sign in on another device" code flow) | 1 d | Low. Only works if the app declares isolation. Likely tied to the device account. |
| C | Re-register: put the device under the Prime Video account, and give Alexa the other identity via a MAP secondary registration (`registerDeviceToSecondaryCustomer` path) | 3-6 d | Whitelist check on registration (`NonWhitelistApp...`). Needs a platform-signed caller (we are root, so a Magisk/system app could call it). May break Alexa and OTA/appstore. Account-lock risk if flagged. |
| D | Hook MAP (LSPosed/Zygisk) to map package to account, so vizzini gets account X tokens and firebat gets Y | 6-12 d | Token minting is server-side per device registration, so a hook cannot fabricate valid tokens for an unregistered account. Fragile across updates. Possible ToS issue. Needs Zygisk (Magisk has it). |
| E | Secondary user / work profile with a separate MAP instance | 5-10 d | Fire OS 8 is Android 11 with multi-user stripped (MultipleProfileHelper is Amazon's own profile layer, not AOSP users). Probably not enabled. DRM (Widevine L1 keyed per device) is the same device, so no extra breakage. |
| F | Replace Prime Video with a non-MAP client (web player, browser, or other app) | 2-4 d | Prime web streams cap at SD/HD in a browser and lose 4K/HDR/Dolby. ToS tolerates it (it is a browser) but video quality is worse. |

## Recommendation
Do B first (1 day, read-only on the APK). If isolation is declared, prototype C. D and E are a last resort. Neither can create a valid second Amazon token without the server registration. Keep aria and the remote-keys tooling untouched.

## Caveats
- Nothing above was run. Class names come from dex strings only. Obfuscated classes are not mapped.
- Which accounts the real Prime Video app accepts depends on its own manifest/server flags, not this image.
