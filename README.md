# PocketHinman-iOS

An iOS app that uses flickering image comparison and image transparency to imitate the functions of a Hinman Collator.

Initial software design: James P. Ascher, DeVan Ard

Funding from the Institute of the Humanities and Global Culture,
University of Virginia, as part of the 2017-18 Public Humanities Lab.

Previously created and maintained by [Ross Harding](https://github.com/dinghar/PocketHinman-iOS).

### To build the app with a new development team

Run `update_xcode_team.sh $YOUR_TEAM` to build the app with the specified [Team ID](https://developer.apple.com/help/account/manage-your-team/locate-your-team-id/).

### To distribute new versions of the app

In the `PocketHinman/PocketHinman/Info.plist`, change the `CFBundleShortVersionString` version to a new version, and change
`CFBundleVersion` to 1. For successive versions, increment the  `CFBundleVersion` until making a new release.
