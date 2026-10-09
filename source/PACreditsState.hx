package;

#if desktop
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.input.keyboard.FlxKey;
import flixel.tweens.FlxEase;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end
import lime.utils.Assets;

#if !flash 
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
#end

import haxe.Json;

import flixel.input.mouse.FlxMouseEvent;

import flixel.ui.FlxBar;

#if mobile
import mobile.MobileButton;
import mobile.TouchInput;
#end

using StringTools;

// CreditsData: name, icon, description, youtube, twitter, quote, role
typedef CreditsData = {
	people:Array<Dynamic>
}

class PACreditsState extends MusicBeatState
{
	var curSelected:Int = 0;
	var progress:Float = 0;

	var creditData:CreditsData;

	var dogeTxt:FlxText;

	private var shaderIntensity:Float;

	private var people:Array<Dynamic> = []; // push people to this depending on the role
	var bg:FlxSprite;
	var creditsText:FlxText;
	var currentGroup:FlxText;

	var quoteText:FlxText;

	var pibbyFNF:Shaders.Pibbified;
	var creditSpr:FlxSprite;

	var creditBar:FlxBar; // this is to show how close you are to the end lol

	var twitter:FlxSprite;
	var youtube:FlxSprite;

	function getCreditJson(path:String):CreditsData {
		var json:String = null;

		json = Paths.getContent(Paths.json(path));

		if (json != null && json.length > 0) {
			return cast Json.parse(json);
		}

		return null;
	}

	var funnyTween:FlxTween;

	override function create()
	{
		FlxG.game.filtersEnabled = true;
		pibbyFNF = new Shaders.Pibbified();

		creditData = getCreditJson('credits');
		people = creditData.people;

		if (ClientPrefs.shaders) FlxG.camera.setFilters([new ShaderFilter(pibbyFNF)]);

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("🧑 | In the Credits", null);
		#end

		openfl.Lib.application.window.title = "Pibby: Apocalypse - Credits";

		persistentUpdate = true;
		bg = new FlxSprite();
        bg.frames = Paths.getSparrowAtlas('fpmenu/background');
        bg.animation.addByPrefix('idle', 'background idle', 30, true);
        bg.animation.play('idle');
        bg.antialiasing = ClientPrefs.globalAntialiasing;
        add(bg);
        bg.screenCenter();

		creditsText = new FlxText(20, 20, 0, '< BACK', 30);
		creditsText.setFormat(Paths.font("menuBUTTONS.ttf"), 54, FlxColor.WHITE, LEFT);
		add(creditsText);

		currentGroup = new FlxText(0, 0, 0, "", 70);
		currentGroup.setFormat(Paths.font("menuBUTTONS.ttf"), 70, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		currentGroup.borderSize = 1.5;
		currentGroup.screenCenter();
		add(currentGroup);

		quoteText = new FlxText(20, 0, 0, "", 20);
		quoteText.setFormat(Paths.font("menuBUTTONS.ttf"), 20, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
		quoteText.borderSize = 1.5;
		quoteText.screenCenter();
		add(quoteText);

		currentGroup.x -= 600;
		quoteText.x -= 600;

		currentGroup.y -= 35;
		quoteText.y += 35;

		creditSpr = new FlxSprite(0, 0);
		add(creditSpr);
		creditSpr.scale.set(0.4, 0.4);
		creditSpr.updateHitbox();
		creditSpr.screenCenter();
		creditSpr.x -= 80;
		creditSpr.y -= 800;
		creditSpr.alpha = 0.6;

		#if !mobile
		FlxMouseEvent.add(creditSpr, function(spr:FlxSprite) {
			spr.scale.x += 0.04;
			spr.scale.y = spr.scale.x; // so it doesnt fuck up
		}, null, function(spr:FlxSprite) {
			FlxTween.tween(spr, {alpha: 1}, 0.15);
		}, function(spr:FlxSprite) {
			FlxTween.tween(spr, {alpha: 0.6}, 0.25);
		});
		#end

		twitter = new FlxSprite(0, 0, Paths.image('pacredits/twitter'));
		add(twitter);
		twitter.alpha = 0.6;
		#if !mobile
		FlxMouseEvent.add(twitter, function(spr:FlxSprite) {
			CoolUtil.browserLoad('https://' + people[curSelected][4]);
		}, null, function(spr:FlxSprite) {
			FlxTween.tween(spr, {alpha: 1}, 0.15);
		}, function(spr:FlxSprite) {
			FlxTween.tween(spr, {alpha: 0.6}, 0.25);
		});
		#end

		youtube = new FlxSprite(0, 0, Paths.image('pacredits/youtube'));
		add(youtube);
		youtube.alpha = 0.6;
		#if !mobile
		FlxMouseEvent.add(youtube, function(spr:FlxSprite) {
			CoolUtil.browserLoad('https://' + people[curSelected][3]);
		}, null, function(spr:FlxSprite) {
			FlxTween.tween(spr, {alpha: 1}, 0.15);
		}, function(spr:FlxSprite) {
			FlxTween.tween(spr, {alpha: 0.6}, 0.25);
		});
		#end

		twitter.scale.x = 0.3;
		twitter.scale.y = 0.3;

		youtube.scale.x = 0.08;
		youtube.scale.y = 0.08;

		twitter.updateHitbox();
		youtube.updateHitbox();

		youtube.setPosition(150, FlxG.height - 130);
		twitter.setPosition(youtube.x - youtube.width, youtube.y);

		#if mobile
		// bigger link icons so they're easy to tap, no hover on touch so no dimming either
		var iconSize:Float = 110;
		twitter.scale.set(iconSize / twitter.frameWidth, iconSize / twitter.frameWidth);
		youtube.scale.set(iconSize / youtube.frameWidth, iconSize / youtube.frameWidth);
		twitter.updateHitbox();
		youtube.updateHitbox();
		twitter.setPosition(40, FlxG.height - iconSize - 40);
		youtube.setPosition(twitter.x + twitter.width + 24, twitter.y);
		twitter.alpha = youtube.alpha = 0.9;

		// readable on a phone, and wrapped so it stays left of the portrait
		quoteText.size = 24;
		quoteText.fieldWidth = 780;

		// every portrait is ~5.7 MB as RGBA and there are ~70 of them, loading them all took ages and ate the RAM.
		// Only the current person and the two next to it are loaded, the rest come in when you swipe to them.
		preloadPerson(curSelected);
		preloadPerson(curSelected + 1);
		preloadPerson(curSelected - 1);
		#else
		for (person in people)
			{
				Paths.returnGraphic('pacreditarts/' + person[1] + 1, null, true);
				Paths.returnGraphic('pacreditarts/' + person[1] + 2, null, true);
			}
		#end

		super.create();

/*		var thenum:Int;
		for (i in 0... people.length) {
			for (i in 1... 2) {
				thenum = i;
			}
			precacheImage('pacreditarts/' + people[i][1] + thenum);
		}

*/

		if (people != null) {
			quoteText.text = people[curSelected][0] + ' - ' + people[curSelected][2] + '\n"' + people[curSelected][5] + '"';
		}

		currentGroup.text = people[curSelected][6];

		creditBar = new FlxBar(30, 10, LEFT_TO_RIGHT, 1210, 10, this, "progress", 0, people.length - 1, true);
		creditBar.createFilledBar(0xFF583A7A, 0xFF09080C);
		add(creditBar);

		dogeTxt = new FlxText(0, FlxG.height - 50, 0, "♪ Now Playing: Credits Theme - By Doge ♪", 8);
		dogeTxt.setFormat(Paths.font("menuBUTTONS.ttf"), 24, FlxColor.WHITE, LEFT);
		dogeTxt.alpha = 0;
		dogeTxt.antialiasing = ClientPrefs.globalAntialiasing;
		add(dogeTxt);

		#if mobile
		// swipes are handled in update (left/right change the person), the back button is bottom right like the other menus
		TouchInput.horizontalNav = false;
		TouchInput.verticalNav = false;
		add(new MobileButton(MobileButtonType.BACK));
		#end

		FlxTween.tween(dogeTxt, {alpha: 1}, 1.5, {
			ease: FlxEase.quadInOut, 
			startDelay: 2,
			onComplete: 
			function (twn:FlxTween)
				{
					FlxTween.tween(dogeTxt, {alpha: 0}, 1.5, {
						ease: FlxEase.quadInOut, startDelay: 2});
				}
		});
	}

/*	function precacheImage(name:String) {
		Paths.returnGraphic(name);
	}
*/

	var quitting:Bool = false;
	var holdTime:Float = 0;
	override function update(elapsed:Float)
	{
		#if mobile
		var backTapped:Bool = TouchInput.tapOver(creditsText, 20);

		// swipe left = next person, swipe right = previous
		var swipeSteps:Int = -TouchInput.swipeStepsX;
		if (swipeSteps != 0)
		{
			changeSelection(swipeSteps);
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		if (TouchInput.tapOver(twitter, 20))
			CoolUtil.browserLoad('https://' + people[curSelected][4]);
		else if (TouchInput.tapOver(youtube, 20))
			CoolUtil.browserLoad('https://' + people[curSelected][3]);
		else if (TouchInput.tapOver(creditSpr))
		{
			creditSpr.scale.x += 0.04;
			creditSpr.scale.y = creditSpr.scale.x;
		}
		#end

		creditSpr.loadGraphic(Paths.returnGraphic('pacreditarts/' + people[curSelected][1] + FlxG.random.int(1, 2), null, true));

		if (FlxG.random.int(0, 1) < 0.01) 
			{
				shaderIntensity = FlxG.random.float(0.2, 0.3);
			}

		if(ClientPrefs.shaders) {
			pibbyFNF.glitchMultiply.value[0] = shaderIntensity;
			pibbyFNF.uTime.value[0] += elapsed;
		}
		
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

			if (controls.BACK #if mobile || backTapped #end)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
				FlxG.sound.playMusic(Paths.music('freakyMenu_${Main.funnyMenuMusic}'));
				quitting = true;
			}
			super.update(elapsed);

		if (controls.UI_LEFT_P) {
			changeSelection(-1);
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		if (controls.UI_RIGHT_P) {
			changeSelection(1);
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		progress = FlxMath.lerp(progress, curSelected, CoolUtil.boundTo(elapsed * 20, 0, 1));
		creditSpr.scale.x = FlxMath.lerp(creditSpr.scale.x, 0.4, CoolUtil.boundTo(elapsed * 3.8, 0, 1));
		creditSpr.scale.y = FlxMath.lerp(creditSpr.scale.y, 0.4, CoolUtil.boundTo(elapsed * 3.8, 0, 1));
	}

	var targetY:Float;

	#if mobile
	function preloadPerson(index:Int) {
		index = (index % people.length + people.length) % people.length;
		Paths.returnGraphic('pacreditarts/' + people[index][1] + 1, null, true);
		Paths.returnGraphic('pacreditarts/' + people[index][1] + 2, null, true);
	}
	#end

	function changeSelection(thing:Int) {
		curSelected += thing;

		// modulo so a swipe of several steps wraps around properly (the old ifs only handled +-1)
		curSelected = (curSelected % people.length + people.length) % people.length;

		#if mobile
		preloadPerson(curSelected + 1);
		preloadPerson(curSelected - 1);
		#end

		if (people != null) {
			quoteText.text = people[curSelected][0] + ' - ' + people[curSelected][2] + '\n"' + people[curSelected][5] + '"';
		}

		currentGroup.text = people[curSelected][6];
	}

	override function destroy() {
		super.destroy();
		FlxG.game.setFilters([]);
	}
}