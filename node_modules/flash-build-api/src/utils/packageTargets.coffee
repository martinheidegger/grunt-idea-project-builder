packageTargets = {
    android: [
        "apk"
        "apk‑captive‑runtime"
        "apk-debug"
        "apk-emulator"
        "apk-profile"
    ]
    ios: [
        "ipa-ad-hoc"
        "ipa-app-store"
        "ipa-debug"
        "ipa-test"
        "ipa-debug-interpreter"
        "ipa-debug-interpreter-interpreter-simulator"
        "ipa-test-interpreter"
        "ipa-test-interpreter-simulator"
    ]
    air: [
        "air"
        "airn"
        "ane"
        "native"
    ]
}

packageTargets.all = []
    .concat(packageTargets.air)
    .concat(packageTargets.android)
    .concat(packageTargets.ios)

module.exports = packageTargets