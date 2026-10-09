package mobile;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;

class MobileHitbox extends FlxBasic
{
	public static inline var COLUMNS:Int = 4;

	// distance between the centers of the player's strums (a touch column is FlxG.width / COLUMNS wide, so they stay inside their column)
	public static inline var STRUM_SPACING:Float = 250;

	/** How far above a strum a touch still counts for its lane (the notes coming down to it) */
	public static inline var REACH:Float = 330;

	public var enabled:Bool = false;

	/** The player's strums, set by PlayState. The touch zones are built around these. */
	public var strums:FlxTypedGroup<StrumNote>;
	public var held(default, null):Array<Bool> = [];

	var down:Array<Bool> = [];
	var pressCallback:Int->Void;
	var releaseCallback:Int->Void;

	public function new(pressCallback:Int->Void, releaseCallback:Int->Void)
	{
		super();
		this.pressCallback = pressCallback;
		this.releaseCallback = releaseCallback;
		visible = false;

		for (i in 0...COLUMNS)
		{
			held.push(false);
			down.push(false);
		}
	}

	public function poll():Void
	{
		for (i in 0...COLUMNS)
			down[i] = false;

		if (enabled)
		{
			for (point in TouchInput.points)
			{
				if (!point.eligible)
					continue;

				var index:Int = laneAt(point.x, point.y);
				if (index >= 0)
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

	/**
	 * Which lane a touch is on, or -1. You press by touching the notes: a lane is the strum plus the stretch above it
	 * where its notes come down (REACH), STRUM_SPACING wide. Touching anywhere else does nothing.
	 * The zones follow the strums, so they stay right when a song moves them.
	 */
	function laneAt(x:Float, y:Float):Int
	{
		if (strums == null)
		{
			// no strums to follow, fall back to splitting the screen in columns
			return Std.int(FlxMath.bound(Math.floor(x / (FlxG.width / COLUMNS)), 0, COLUMNS - 1));
		}

		for (i in 0...COLUMNS)
		{
			var strum:StrumNote = strums.members[i];
			if (strum == null || !strum.exists)
				continue;

			if (Math.abs(x - (strum.x + strum.width / 2)) <= STRUM_SPACING / 2 && y >= strum.y - REACH)
				return i;
		}
		return -1;
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
