package mobile;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import mobile.MobileButton;

class TouchPoint
{
	public var id:Int;
	public var startX:Float;
	public var startY:Float;
	public var x:Float;
	public var y:Float;
	public var anchorX:Float;
	public var anchorY:Float;
	public var heldTime:Float = 0;
	public var travelled:Float = 0;
	public var swiped:Bool = false;
	public var onButton:Bool = false;
	public var eligible:Bool = false;

	public function new(id:Int, x:Float, y:Float)
	{
		this.id = id;
		this.x = this.startX = this.anchorX = x;
		this.y = this.startY = this.anchorY = y;
	}
}

class TouchInput
{
	public static inline var TAP_MAX_TIME:Float = 0.3;
	public static inline var TAP_MAX_DISTANCE:Float = 28;
	public static inline var SWIPE_STEP:Float = 80;

	public static var points(default, null):Array<TouchPoint> = [];
	public static var buttons(default, null):Array<MobileButton> = [];

	public static var swipeUp(default, null):Bool = false;
	public static var swipeDown(default, null):Bool = false;
	public static var swipeLeft(default, null):Bool = false;
	public static var swipeRight(default, null):Bool = false;

	public static var swipeStepsX(default, null):Int = 0;
	public static var swipeStepsY(default, null):Int = 0;

	public static var tap(default, null):Bool = false;
	public static var tapX(default, null):Float = 0;
	public static var tapY(default, null):Float = 0;

	public static var backPressed(default, null):Bool = false;
	public static var pausePressed(default, null):Bool = false;

	public static var tapAccepts:Bool = true;
	public static var verticalNav:Bool = true;
	public static var horizontalNav:Bool = true;
	public static var gameplay:Bool = false;

	public static var navUp(get, never):Bool;
	public static var navDown(get, never):Bool;
	public static var navLeft(get, never):Bool;
	public static var navRight(get, never):Bool;
	public static var acceptTap(get, never):Bool;

	static var initialized:Bool = false;

	public static function init():Void
	{
		if (!initialized)
		{
			initialized = true;
			FlxG.signals.preStateSwitch.add(resetNavigation);
		}

		if (FlxG.plugins.get(TouchInputPlugin) == null)
			FlxG.plugins.add(new TouchInputPlugin());
	}

	public static function tapOver(object:FlxObject, padding:Float = 0):Bool
	{
		if (!tap || object == null || !object.exists || !object.alive)
			return false;

		var position:FlxPoint = object.getScreenPosition(null, object.camera);
		var hit:Bool = tapX >= position.x - padding
			&& tapX <= position.x + object.width + padding
			&& tapY >= position.y - padding
			&& tapY <= position.y + object.height + padding;
		position.put();

		if (hit)
			tap = false;

		return hit;
	}

	public static function consumeTap():Void
	{
		tap = false;
	}

	public static function poll(elapsed:Float):Void
	{
		swipeUp = swipeDown = swipeLeft = swipeRight = false;
		swipeStepsX = 0;
		swipeStepsY = 0;
		tap = false;
		backPressed = false;
		pausePressed = false;

		var state = FlxG.state;
		var gestures:Bool = !(gameplay && state != null && state.subState == null);
		var seen:Array<Int> = [];

		for (touch in FlxG.touches.list)
		{
			var id:Int = touch.touchPointID;
			seen.push(id);

			var point:TouchPoint = getPoint(id);
			if (touch.justPressed || (point == null && touch.justReleased))
			{
				if (point != null)
					points.remove(point);

				point = new TouchPoint(id, touch.screenX, touch.screenY);
				point.onButton = pressButtons(point);
				point.eligible = gameplay && !point.onButton && state != null && state.subState == null;
				#if TOUCH_DEBUG
				trace("TOUCHDBG down " + point.x + "," + point.y + " onButton=" + point.onButton + " eligible=" + point.eligible);
				#end
				points.push(point);
			}

			if (point == null)
				continue;

			point.heldTime += elapsed;
			point.x = touch.screenX;
			point.y = touch.screenY;

			if (!point.onButton && gestures)
				track(point);

			if (touch.justReleased)
			{
				if (!point.onButton && gestures && !point.swiped && point.travelled <= TAP_MAX_DISTANCE && point.heldTime <= TAP_MAX_TIME)
				{
					tap = true;
					#if TOUCH_DEBUG
					trace("TOUCHDBG tap " + point.x + "," + point.y);
					#end
					tapX = point.x;
					tapY = point.y;
				}
				points.remove(point);
			}
		}

		var i:Int = points.length;
		while (i-- > 0)
		{
			if (seen.indexOf(points[i].id) < 0)
				points.splice(i, 1);
		}
	}

	static function track(point:TouchPoint):Void
	{
		var fromStartX:Float = point.x - point.startX;
		var fromStartY:Float = point.y - point.startY;
		var distance:Float = Math.sqrt(fromStartX * fromStartX + fromStartY * fromStartY);
		if (distance > point.travelled)
			point.travelled = distance;

		var dx:Float = point.x - point.anchorX;
		var dy:Float = point.y - point.anchorY;
		var absX:Float = Math.abs(dx);
		var absY:Float = Math.abs(dy);

		if (absY >= SWIPE_STEP && absY >= absX)
		{
			var steps:Int = Std.int(absY / SWIPE_STEP);
			var direction:Int = dy < 0 ? -1 : 1;

			if (direction < 0)
				swipeUp = true;
			else
				swipeDown = true;

			swipeStepsY += direction * steps;
			point.swiped = true;
			point.anchorX = point.x;
			point.anchorY += direction * steps * SWIPE_STEP;
		}
		else if (absX >= SWIPE_STEP)
		{
			var steps:Int = Std.int(absX / SWIPE_STEP);
			var direction:Int = dx < 0 ? -1 : 1;

			if (direction < 0)
				swipeLeft = true;
			else
				swipeRight = true;

			swipeStepsX += direction * steps;
			#if TOUCH_DEBUG
			trace("TOUCHDBG swipeX " + (direction * steps));
			#end
			point.swiped = true;
			point.anchorX += direction * steps * SWIPE_STEP;
			point.anchorY = point.y;
		}
	}

	static function pressButtons(point:TouchPoint):Bool
	{
		for (button in buttons)
		{
			if (!button.canTouch() || !button.contains(point.x, point.y))
				continue;

			button.press();

			switch (button.type)
			{
				case BACK:
					backPressed = true;
				case PAUSE:
					pausePressed = true;
			}
			return true;
		}
		return false;
	}

	static function getPoint(id:Int):TouchPoint
	{
		for (point in points)
		{
			if (point.id == id)
				return point;
		}
		return null;
	}

	static function resetNavigation():Void
	{
		tapAccepts = true;
		verticalNav = true;
		horizontalNav = true;
		gameplay = false;
	}

	static inline function get_navUp():Bool
		return verticalNav && swipeDown;

	static inline function get_navDown():Bool
		return verticalNav && swipeUp;

	static inline function get_navLeft():Bool
		return horizontalNav && swipeLeft;

	static inline function get_navRight():Bool
		return horizontalNav && swipeRight;

	static inline function get_acceptTap():Bool
		return tap && tapAccepts && !gameplay;
}

class TouchInputPlugin extends FlxBasic
{
	public function new()
	{
		super();
		visible = false;
	}

	override public function update(elapsed:Float):Void
	{
		TouchInput.poll(elapsed);
	}
}
