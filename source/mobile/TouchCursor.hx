package mobile;

import flixel.FlxBasic;
import flixel.FlxG;
import openfl.display.Sprite;

/**
 * Small blue dot that follows the finger while the screen is touched, then fades out.
 *
 * It's a plain OpenFL sprite on top of FlxG.game instead of a Flixel camera, so it doesn't change
 * FlxG.cameras (PauseSubState and FunkinLua use the last camera in that list as "the top one").
 */
class TouchCursor extends FlxBasic
{
	/** Diameter in game pixels */
	public static inline var SIZE:Float = 26;

	static inline var COLOR:Int = 0x2F8CFF;
	static inline var ALPHA:Float = 0.9;
	static inline var FADE_TIME:Float = 0.2;

	var dot:Sprite;
	var drawnScale:Float = -1;

	public function new()
	{
		super();
		visible = false;

		dot = new Sprite();
		dot.mouseEnabled = false;
		dot.mouseChildren = false;
		dot.visible = false;
		FlxG.game.addChild(dot);
	}

	override public function update(elapsed:Float):Void
	{
		var scaleX:Float = FlxG.scaleMode.scale.x;
		var scaleY:Float = FlxG.scaleMode.scale.y;

		if (TouchInput.points.length > 0)
		{
			var point = TouchInput.points[0];
			redraw(scaleX);
			// touch positions are in game pixels, FlxG.game's children are in window pixels
			dot.x = point.x * scaleX;
			dot.y = point.y * scaleY;
			dot.alpha = ALPHA;
			dot.visible = true;
		}
		else if (dot.visible)
		{
			dot.alpha -= elapsed * ALPHA / FADE_TIME;
			if (dot.alpha <= 0)
				dot.visible = false;
		}

		// keep it above anything added to the game later (sound tray, debugger...)
		if (dot.visible && FlxG.game.getChildIndex(dot) != FlxG.game.numChildren - 1)
			FlxG.game.setChildIndex(dot, FlxG.game.numChildren - 1);
	}

	function redraw(scale:Float):Void
	{
		if (scale == drawnScale)
			return;
		drawnScale = scale;

		var radius:Float = SIZE / 2 * scale;
		dot.graphics.clear();
		dot.graphics.lineStyle(Math.max(1, 2 * scale), 0xFFFFFF, 0.9);
		dot.graphics.beginFill(COLOR, 1);
		dot.graphics.drawCircle(0, 0, radius);
		dot.graphics.endFill();
	}

	override public function destroy():Void
	{
		if (dot != null && dot.parent != null)
			dot.parent.removeChild(dot);
		dot = null;
		super.destroy();
	}
}
