package mobile;

import flixel.FlxG;
import flixel.FlxSprite;

enum MobileButtonType
{
	BACK;
	PAUSE;
}

class MobileButton extends FlxSprite
{
	public static inline var MARGIN:Float = 16;
	public static inline var HIT_PADDING:Float = 24;

	public var type(default, null):MobileButtonType;
	public var inSubState(default, null):Bool;

	public function new(type:MobileButtonType, inSubState:Bool = false)
	{
		super();
		this.type = type;
		this.inSubState = inSubState;

		var prefix:String = 'back';
		var targetSize:Float = 118;
		switch (type)
		{
			case BACK:
				prefix = 'back';
			case PAUSE:
				prefix = 'pause';
		}

		frames = Paths.getSparrowAtlas('mobile/' + prefix + 'Button');
		animation.addByIndices('idle', prefix, [0], '', 24, false);
		animation.addByPrefix('press', prefix, 24, false);
		animation.play('idle');

		antialiasing = ClientPrefs.globalAntialiasing;
		scrollFactor.set(0, 0);

		var factor:Float = targetSize / frameWidth;
		scale.set(factor, factor);
		updateHitbox();

		switch (type)
		{
			case BACK:
				setPosition(FlxG.width - width - MARGIN, FlxG.height - height - MARGIN);
			case PAUSE:
				setPosition(FlxG.width - width - MARGIN, MARGIN);
		}

		TouchInput.buttons.push(this);
	}

	public function canTouch():Bool
	{
		if (!exists || !alive || !visible || !active || alpha <= 0)
			return false;

		return (FlxG.state.subState != null) == inSubState;
	}

	public function contains(touchX:Float, touchY:Float):Bool
	{
		return touchX >= x - HIT_PADDING
			&& touchX <= x + width + HIT_PADDING
			&& touchY >= y - HIT_PADDING
			&& touchY <= y + height + HIT_PADDING;
	}

	public function press():Void
	{
		animation.play('press', true);
	}

	override public function destroy():Void
	{
		TouchInput.buttons.remove(this);
		super.destroy();
	}
}
