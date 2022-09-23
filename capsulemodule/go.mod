module github.com/bots-garden/capsule/capsulemodule

go 1.18

replace github.com/bots-garden/capsule/capsulemodule => ../capsulemodule

replace github.com/bots-garden/capsule/commons => ../commons

replace (
	github.com/bots-garden/capsule v0.2.2 => ../
	github.com/bots-garden/capsule v0.2.3 => ../
)

replace (
	github.com/bots-garden/capsule/commons v0.2.2 => ../commons
	github.com/bots-garden/capsule/commons v0.2.3 => ../commons
)

require github.com/bots-garden/capsule/commons v0.2.2
