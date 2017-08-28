## 0.8.2

- Finally figured out what the problem was with issue [#18](https://github.com/oriolmirosa/open-files/issues/18). The removal of elements depended on their indeces, but when several were removed at the same time (or quickly one after the other, which became a problem because of the delays and animations), then the indeces were non-existent and that led to errors. I assigned unique ids for each element, so now their removal does not depend on their index and should always be accurate

## 0.8.1

- Yet another attempt to take care of bug [#18](https://github.com/oriolmirosa/open-files/issues/18)

## 0.8.0

- Rewrite of large portions of the package in order to make it more stable. Hopefully this takes care of bug [#18](https://github.com/oriolmirosa/open-files/issues/18)
- Added the ability to re-sort files in the 'open files' panel automatically when a file has been renamed, or when it has been saved for the first time after creating a new file
- The icons should now change automatically and immediately when a file name change implies a filetype change, and also when a file is saved for the first time
- For both the `file-icons` and the `seti-icons` packages, the icons in the 'open files' panel now mirror those of the tabs for the various special Atom views: 'Settings', 'Deprecation Cop', 'Timecop', 'About', and 'Project Find Results'. For `seti-icons`, the icon for a new file is now also the same as in the tabs

## 0.7.2

- Attemp to fix bug [#18](https://github.com/oriolmirosa/open-files/issues/18)

## 0.7.1

- Added a donation button to the readme page

## 0.7.0

- When several panels are open, the title for the 'open files' panels now includes PANEL #, with the number showing the order in which the panels were opened. When panels are closed, the numbers of the panels are re-calculated so that they reflect the panels present in the workspace

## 0.6.2

- Fixed a bug that threw an error whenever a new file was created after closing the 'Settings' page (mentioned in [#17](https://github.com/oriolmirosa/open-files/issues/17)
- Prepared the package so that it will continue to work when 1.18 is released (it works normally on 1.18beta2 now)

## 0.6.1

- Fixed a bug that made the icons from the file-icons package to not be used in the 'open files' panel [#15](https://github.com/oriolmirosa/open-files/issues/15)

## 0.6.0

- Added delay before a new file appears in the 'open files' panel. This prevents the whole tree view from sliding downward too quickly and thus making the second click (when double-clicking) to be done on a different file. The delay is configurable (in milliseconds) in the setting for the package (default is 1000 ms, i.e. 1 second)
- Added animation when a file is added to (or removed from) the 'open files' panel. The animation duration is also configurable (default is 300 ms)

## 0.5.7

- Fixed regression that led to [#13](https://github.com/oriolmirosa/open-files/issues/13)

## 0.5.6

- Fix for [#10](https://github.com/oriolmirosa/open-files/issues/10)

## 0.5.5

- Fix for [#11](https://github.com/oriolmirosa/open-files/issues/11)

## 0.5.4

- Changes to make the package work in 1.17.0. It should still work with 1.16.0 out of the box for those who prefer not to update

## 0.5.3

- Minor changes to attempt to fix [#10](https://github.com/oriolmirosa/open-files/issues/10)

## 0.5.2

- Fixed crash introduced in 1.16.0, when prepend() wouldn't work anymore. Added the polyfill so that it continues to work

## 0.5.1

- Toggling the tree-view now doesn't create more 'FOLDERS' labels or destroys the open-files pane (should also fix [#9](https://github.com/oriolmirosa/open-files/issues/9))

## 0.4.2

- Minor to change to avoid deprecation warning about path.dirname and path.extname requiring a string as an argument

## 0.4.1

- Fixed regression that made newly opened files not appear in the open files list if there were no open files to begin with
- Fixed sorting so that directories are now ordered properly

## 0.4.0

- Added the ability to sort the open files list by multiple criteria (filename, extension, and directory)

## 0.3.0

- The open files panel is now collapsable. You can click on the 'OPEN FILES' label to collapse the list of open files (fixes [#4](https://github.com/oriolmirosa/open-files/issues/4))
- Added settings option to toggle whether the open files panel is collapsable
- The line-height of the 'open files' items now is reduced when the 'compact tree view' option is selected in the atom-material-ui theme (fixes [#3](https://github.com/oriolmirosa/open-files/issues/3))

## 0.2.3

- Now open-files works when the settings tab (or any other tab with no path) is open (fixes [#2](https://github.com/oriolmirosa/open-files/issues/2))

## 0.1.0 - First Release
