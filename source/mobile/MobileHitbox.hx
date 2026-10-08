package mobile;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;

class MobileHitbox extends FlxTypedGroup<FlxSprite>
{
	public static inline var COLUMNS:Int = 4;
	public static inline var PRESSED_ALPHA:Float = 0.45;
	public static inline var FADE_SPEED:Float = 3;

	static var COLORS:Array<Int> = [0xFFC24B99, 0xFF00FFFF, 0xFF12FA05, 0xFFF9393F];

	public var enabled:Bool = false;
	public var held(default, null):Array<Bool> = [];

	var columns:Array<FlxSprite> = [];
	var pressCallback:Int->Void;
	var releaseCallback:Int->Void;

	public function new(pressCallback:Int->Void, releaseCallback:Int->Void)
	{
		super();
		this.pressCallback = pressCallback;
		this.releaseCallback = releaseCallback;

		var columnWidth:Int = Math.ceil(FlxG.width / COLUMNS);

		for (i in 0...COLUMNS)
		{
			var color:FlxColor = COLORS[i];
			var clear:FlxColor = FlxColor.fromRGB(color.red, color.green, color.blue, 0);

			var column:FlxSprite = FlxGradient.createGradientFlxSprite(columnWidth, FlxG.height, [clear, color]);
			column.x = i * columnWidth;
			column.y = 0;
			column.alpha = 0;
			column.scrollFactor.set(0, 0);

			columns.push(column);
			held.push(false);
			add(column);
		}
	}

	public function poll():Void
	{
		var down:Array<Bool> = [for (i in 0...COLUMNS) false];

		var columnWidth:Float = FlxG.width / COLUMNS;
		for (point in TouchInput.points)
		{
			if (!point.eligible || !enabled)
				continue;

			var index:Int = Std.int(FlxMath.bound(Math.floor(point.x / columnWidth), 0, COLUMNS - 1));
			down[index] = true;
		}

		for (i in 0...COLUMNS)
		{
			if (down[i] && !held[i])
			{
				held[i] = true;
				columns[i].alpha = PRESSED_ALPHA;
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
			columns[i].alpha = 0;
			if (held[i])
			{
				held[i] = false;
				releaseCallback(i);
			}
		}
	}

	override public function update(elapsed:Float):Void
	{
		for (i in 0...COLUMNS)
		{
			if (!held[i] && columns[i].alpha > 0)
				columns[i].alpha = Math.max(0, columns[i].alpha - FADE_SPEED * elapsed);
		}
		super.update(elapsed);
	}
}
