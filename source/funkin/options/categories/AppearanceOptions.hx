package funkin.options.categories;

class AppearanceOptions extends OptionsScreen {
	public override function new() {
		super("Appearance", "Change Appearance options such as Antialiasing & Menu Flashing...");
		add(new NumOption(
			"Framerate",
			"Pretty self explanatory, isn't it?",
			30, // minimum
			240, // maximum
			10, // change
			"framerate", // save name or smth
			__changeFPS)); // callback
		add(new Checkbox(
			"Antialiasing",
			"If unchecked, will disable antialiasing on every sprite. Can boost performances at the cost of sharper, more pixel-looking sprites.",
			"antialiasing"));
		add(new Checkbox(
			"Colored Healthbar",
			"If unchecked, the game will use the original Red/Green health bar colors from the vanilla FNF engine.",
			"colorHealthBar"));
		add(new Checkbox(
			"Pixel Perfect Effect",
			"If checked, Week 6 will have a pixel perfect effect to it enabled, aligning every pixel on the screen.",
			"week6PixelPerfect"));
		add(new Checkbox(
			"Gameplay Shaders",
			"If unchecked, gameplay shaders (visual effects like Thorns's Chromatic Aberration) won't be loaded; this may be helpful on weak devices.",
			"gameplayShaders"));
		add(new Checkbox(
			"Menu Flashing",
			"If unchecked, will disable the menu's flashing effects when you select an option in the Main Menu, and other flashes will be slower.",
			"flashingMenu"));
		add(new Checkbox(
			"Note Splashes",
			"If unchecked, makes the note play a splash animation every hit.",
			"splashesEnabled"));
		add(new Checkbox(
			"Low Memory Mode",
			"If checked, will disable certain background elements in stages to reduce memory usage.",
			"lowMemoryMode"));
		#if sys
		if (!Main.forceGPUOnlyBitmapsOff) {
			add(new Checkbox(
				"VRAM-Only Sprites",
				"If checked, will only store the bitmaps in the GPU, freeing a LOT of memory (EXPERIMENTAL). Turning this off will consume a lot of memory, especially on bigger sprites. If you aren't sure, leave this on.",
				"gpuOnlyBitmaps"));
		}
		#end
		add(new Checkbox(
			"Auto Pause",
			"If checked, switching windows will pause the game.",
			"autoPause"));
	}

	private function __changeFPS(change:Float) {
		// if statement cause of the flixel warning
		if(FlxG.updateFramerate < Std.int(change))
			FlxG.drawFramerate = FlxG.updateFramerate = Std.int(change);
		else
			FlxG.updateFramerate = FlxG.drawFramerate = Std.int(change);
	}
}
