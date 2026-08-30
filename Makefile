.DEFAULT_GOAL := preview

format:
	qmlformat -i ./package/contents/ui/*.qml
	qmlformat -i ./package/contents/scripts/*.js

install:
	kpackagetool6 --type Plasma/Applet --install ./package

uninstall:
	kpackagetool6 --type Plasma/Applet --remove top.lyriks.lyriks

upgrade:
	kpackagetool6 --type Plasma/Applet --upgrade ./package
	systemctl --user restart plasma-plasmashell.service

preview:
	plasmoidviewer -a ./package
