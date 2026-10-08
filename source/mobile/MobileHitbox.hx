package mobile;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.math.FlxMath;

class MobileHitbox extends FlxBasic
{
	public static inline var COLUMNS:Int = 4;

	public var enabled:Bool = false;
	public var held(default, null):Array<Bool> = [];

	var pressCallback:Int->Void;
	var releaseCallback:Int->Void;

	public function new(pressCallback:Int->Void, releaseCallback:Int->Void)
	{
		super();
		this.pressCallback = pressCallback;
		this.releaseCallback = releaseCallback;
		visible = false;

		for (i in 0...COLUMNS)
			held.push(false);
	}

	public function poll():Void
	{
		var down:Array<Bool> = [for (i in 0...COLUMNS) false];

		if (enabled)
		{
			var columnWidth:Float = FlxG.width / COLUMNS;
			for (point in TouchInput.points)
			{
				if (!point.eligible)
					continue;

				var index:Int = Std.int(FlxMath.bound(Math.floor(point.x / columnWidth), 0, COLUMNS - 1));
				down[index] = true;
			}
		}

		for (i in 0...COLUMNS)
		{
			if (down[i] && !held[i])
			{
				held[i] = true;
				pressCallback(i);
			}
			else if (!down[i] && held[i])
			{
				held[i] = false;
				releaseCallback(i);
			}
		}
	}

	public function releaseAll():Void
	{
		for (i in 0...COLUMNS)
		{
			if (held[i])
			{
				held[i] = false;
				releaseCallback(i);
			}
		}
	}
}
