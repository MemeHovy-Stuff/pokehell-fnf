package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.text.FlxText;
import flixel.FlxSubState;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

class GameOverSubstate extends MusicBeatSubstate
{
	var bf:Boyfriend;
	var camFollow:FlxPoint;
	var camFollowPos:FlxObject;
	var updateCamera:Bool = false;

	var deadText:FlxText;

	var stageSuffix:String = "";

	var lePlayState:PlayState;

	public static var characterName:String = 'bf';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';
	public static var deathReason = 'Hello. You are dead.';

	public static function resetVariables() {
		characterName = 'bf';
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';
	}

	public function new(x:Float, y:Float, camX:Float, camY:Float, state:PlayState)
	{
		lePlayState = state;
		state.setOnLuas('inGameOver', true);
		super();

		deathSoundName = PlayState.soundPrefix + 'fnf_loss_sfx';

		Conductor.songPosition = 0;

		switch(PlayState.SONG.player1){
			case 'bf'|'cursedSally':
				//characterName = 'RIPEEVEELOL';
				deathSoundName = 'fnf_loss_sfx';
			case 'RIPEEVEELOL':
				characterName = 'RIPEEVEELOL';
				deathSoundName = 'fnf_loss_sfx';
			case 'sallyFloombo':
				characterName = 'sallyFloombo';
				deathSoundName = 'vineboom';
			default:
				characterName = 'RIPBFLOL';
				deathSoundName = 'fnf_loss_sfx_bf';
		}

		bf = new Boyfriend(x, y, characterName);
		add(bf);

		FlxG.camera.flash(1,FlxColor.WHITE);

		camFollow = new FlxPoint(bf.getGraphicMidpoint().x, bf.getGraphicMidpoint().y);

		deadText = new FlxText(bf.getGraphicMidpoint().x, bf.y + 10, 1024,deathReason,32);
		deadText.setFormat(Paths.font('righteous.ttf'), 32, FlxColor.WHITE, LEFT);
		deadText.alpha = 0;
		FlxTween.tween(deadText,{alpha: 1}, 2, {startDelay: 2});
		add(deadText);

		FlxG.sound.play(Paths.sound(deathSoundName));
		Conductor.changeBPM(100);
		// FlxG.camera.followLerp = 1;
		// FlxG.camera.focusOn(FlxPoint.get(FlxG.width / 2, FlxG.height / 2));
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		bf.playAnim('firstDeath');

		var exclude:Array<Int> = [];

		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2));
		add(camFollowPos);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		lePlayState.callOnLuas('onUpdate', [elapsed]);
		if(updateCamera) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 0.6, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		}

		if (controls.ACCEPT)
		{
			endBullshit();
		}

		if (controls.BACK)
		{
			FlxG.sound.music.stop();
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;

			if (PlayState.isStoryMode)
				MusicBeatState.switchState(new StoryMenuState());
			else
				MusicBeatState.switchState(new FreeplayState());

			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			lePlayState.callOnLuas('onGameOverConfirm', [false]);
		}

		if (bf.animation.curAnim.name == 'firstDeath')
		{
			if(bf.animation.curAnim.curFrame == 12)
			{
				FlxG.camera.follow(camFollowPos, LOCKON, 1);
				updateCamera = true;
			}

			if (bf.animation.curAnim.finished)
			{
				coolStartDeath();
				bf.startedDeath = true;
			}
		}

		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}
		lePlayState.callOnLuas('onUpdatePost', [elapsed]);
	}

	override function beatHit()
	{
		super.beatHit();

		//FlxG.log.add('beat');
	}

	var isEnding:Bool = false;

	function coolStartDeath(?volume:Float = 1):Void
	{
		FlxG.sound.playMusic(Paths.music(loopSoundName), volume);
	}

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;
			bf.playAnim('deathConfirm', true);
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music(endSoundName));
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					MusicBeatState.resetState();
				});
			});
			lePlayState.callOnLuas('onGameOverConfirm', [true]);
		}
	}
}
