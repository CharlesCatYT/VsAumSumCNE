function postUpdate() {
    switch(strumLines[curCameraTarget].characters[0].getAnimName()) {
        case "singLEFT": camFollow.x -= 20;
        case "singDOWN": camFollow.y += 20;
        case "singUP": camFollow.y -= 20;
        case "singRIGHT": camFollow.x += 20;
    }
}