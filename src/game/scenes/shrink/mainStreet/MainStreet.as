package game.scenes.shrink.mainStreet
{
	import com.greensock.easing.Linear;
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.data.AudioWrapper;
	import engine.managers.SoundManager;
	
	import game.components.entity.OriginPoint;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.hit.EntityIdList;
	import game.components.hit.HitTest;
	import game.components.hit.Platform;
	import game.components.scene.SceneInteraction;
	import game.creators.ui.ToolTipCreator;
	import game.data.sound.SoundModifier;
	import game.data.ui.ToolTipType;
	import game.scene.SceneSound;
	import game.scene.template.PlatformerGameScene;
	import game.scene.template.ads.AdBlimpGroup;
	import game.scenes.custom.AdMiniBillboard;
	import game.scenes.shrink.ShrinkEvents;
	import game.scenes.shrink.bedroomShrunk02.BedroomShrunk02;
	import game.scenes.shrink.mainStreet.StreamerSystem.Streamer;
	import game.scenes.shrink.mainStreet.StreamerSystem.StreamerSystem;
	import game.scenes.shrink.mainStreet.StretchSwingSystem.StretchSwing;
	import game.scenes.shrink.mainStreet.StretchSwingSystem.StretchSwingSystem;
	import game.scenes.shrink.silvaOfficeShrunk02.SilvaOfficeShrunk02;
	import game.systems.hit.HitTestSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	
	public class MainStreet extends PlatformerGameScene
	{
		private var _events:ShrinkEvents;
		private const JUMP_MULTIPLIER:Number = 1.25;
		private const INTRO:String = "Avenue_A_Intro.mp3";
		private const MAIN_THEME:String = "Avenue_A.mp3";

		public function MainStreet()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/shrink/mainStreet/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			// TEMPORARY :: this is a hack for web, should be able to maintain last scene
			if( PlatformUtils.inBrowser )
			{
				if( shellApi.checkEvent(_events.SHRUNK) && !shellApi.checkEvent(_events.SHRUNK_SILVA))
				{
					if(shellApi.checkEvent(_events.IN_SILVAS_OFFICE))
						shellApi.loadScene(SilvaOfficeShrunk02);
					else
						shellApi.loadScene(BedroomShrunk02);
					return;
				}
			}
			super.load();
		}

		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			_events = events as ShrinkEvents;
			
			// tool tip on rope
			var rope:Entity = EntityUtils.createSpatialEntity(super, super.hitContainer["climb"]);
			rope.get(Display).alpha = 0;
			// tool tip text (blank if blimp takeover)
			var toolTipText:String = (super.getGroupById(AdBlimpGroup.GROUP_ID) == null) ? "TRAVEL" : "";			
			ToolTipCreator.addToEntity(rope,ToolTipType.EXIT_UP, toolTipText);
			// rope behavior
			var interaction:Interaction = InteractionCreator.addToEntity(rope, [InteractionCreator.CLICK]);
			interaction.click.add(climbToBlimp);

			addSystem(new StretchSwingSystem());
			addSystem(new HitTestSystem());
			
			if(!PlatformUtils.isMobileOS)
			{
				setUpFlies();
				setUpStreamer();
			}
			
			setUpSwings();
			setUpSlide();
			setUpThemeMusic();// making it so it plays the intro and when finished plays the main theme
			
			var minibillboard:AdMiniBillboard = new AdMiniBillboard(this,super.shellApi, new Point(3515, 1120),"minibillboard/minibillboardMedLegs.swf");	

		}
		
		private function climbToBlimp(ent:Entity):void
		{
			var rope:MovieClip = super.hitContainer["climb"];
			var top:Number = rope.y - rope.height / 2;
			CharUtils.followPath(player, new <Point>[new Point(rope.x, top)], playerReachedTopBlimp, false, false, new Point(40, 40));
		}		
		
		private function playerReachedTopBlimp(...args):void
		{
			// if blimp takeover not active, then load map
			if (super.getGroupById(AdBlimpGroup.GROUP_ID) == null)
				getEntityById("exitToMap").get(SceneInteraction).activated = true;
		}
		
		override public function destroy():void
		{
			if(introWrapper != null)
			{
				introWrapper.complete.removeAll();
				introWrapper = null;
			}
			super.destroy();
		}
		
		private var introWrapper:AudioWrapper;
		
		private function setUpThemeMusic():void
		{
			if(!shellApi.checkEvent(_events.INTRO_PLAYED))
			{
				shellApi.completeEvent(_events.INTRO_PLAYED);
				var audio:Audio = AudioUtils.getAudio(this, SceneSound.SCENE_SOUND);
				introWrapper = audio.play(SoundManager.MUSIC_PATH + INTRO);
				introWrapper.complete.addOnce(completeHandler );
			}
		}
		
		private function completeHandler():void
		{
			var audio:Audio = AudioUtils.getAudio(this, SceneSound.SCENE_SOUND);
			if(audio)
			{
				audio.play(SoundManager.MUSIC_PATH + MAIN_THEME, true);
			}
		}
		
		private function setUpSlide():void
		{
			var entity:Entity = getEntityById("slide2");
			entity.add(new HitTest(onSlide, false,leaveSlide));
			entity = getEntityById("slide1");
			entity.add(new HitTest(onSlide));
		}

		private function onSlide(entity:Entity, id:String):void
		{
			var char:Entity = getEntityById(id);
			var control:CharacterMotionControl = char.get(CharacterMotionControl);
			if(control != null)
			{
				control.allowAutoTarget = false;
				if(Motion(char.get(Motion)).velocity.x <= 0)
					CharUtils.setDirection(char, false);
			}
		}
		
		private function leaveSlide(entity:Entity, id:String):void
		{
			var hitEntity:Entity = getEntityById(id);
			var motion:Motion = hitEntity.get(Motion);
			if(motion != null)
			{
				if(motion.velocity.x < -400)
				{
					motion.velocity.x = -500;
					motion.velocity.y = motion.velocity.x * JUMP_MULTIPLIER;
					motion.acceleration.setTo(0, 0);
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "whoosh_08.mp3");
				}
			}
		}
		
		private function setUpStreamer():void
		{
			var clip:MovieClip = _hitContainer["streamer"];
				
			addSystem(new StreamerSystem());
			var streamer:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			streamer.add(new Tween());
			streamer.add(new Streamer(clip, 90, shellApi.inputEntity.get(Spatial),true,2,7.5,1.25, 15, 10));
			Streamer(streamer.get(Streamer)).clampPositive = true;
			
			var audioRange:AudioRange = new AudioRange(1000,.5,1,Quad.easeIn);
			
			streamer.add(new Audio()).add(new Id("streamer")).add(audioRange);
			
			Audio(streamer.get(Audio)).play("effects/flag_flapping_01.mp3",true, SoundModifier.POSITION);
		}
		
		private function setUpSwings():void
		{
			for(var i:int = 1; i <= 2; i++)
			{
				var clip:MovieClip = _hitContainer["swing"+i];
				var swing:Entity = EntityUtils.createSpatialEntity(this, clip);
				swing.add(new Tween());
				
				var swingHitClip:MovieClip = _hitContainer["swingHit"+i];
				var swingHit:Entity = EntityUtils.createSpatialEntity(this, swingHitClip);
				swingHit.add(new Platform());
				swingHit.add(new EntityIdList());
				
				swing.add(new StretchSwing(swingHit, 1.05,"metal_chains_01.mp3"));
			}
		}
		
		private function setUpFlies():void
		{
			var basePosition:Rectangle = new Rectangle(250, 1350, 25, 25);
			
			var sprite:Sprite = new Sprite();
			sprite.x = basePosition.x + basePosition.width / 2;
			sprite.y = basePosition.y + basePosition.height / 2;
			
			var audioEntity:Entity = EntityUtils.createSpatialEntity(this,sprite, _hitContainer);
			audioEntity.add(new Audio()).add( new AudioRange(1000, 0, 1, Quad.easeOut));
			Audio(audioEntity.get(Audio)).play(SoundManager.EFFECTS_PATH +"insect_flies_02_loop.mp3", true, SoundModifier.POSITION);
			
			for(var i:int = 1; i <= 4; i++)
			{
				var clip:Shape = new Shape();
				clip.graphics.beginFill(0,1);
				clip.graphics.drawCircle(0,0,2);
				clip.graphics.endFill();
				
				var fly:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
				
				var flyPos:Spatial = fly.get(Spatial);
				flyPos.x = basePosition.x + Math.random() * basePosition.width;
				flyPos.y = basePosition.y + Math.random() * basePosition.height;
				
				fly.add(new OriginPoint(flyPos.x, flyPos.y));
				fly.add(new Tween());
				
				moveFly(fly);
			}
		}
		
		private function moveFly(fly:Entity):void
		{
			var origin:OriginPoint = fly.get(OriginPoint);
			var targetX:Number = (Math.random() - 0.5) * 250 + origin.x;
			var targetY:Number = (Math.random() - 0.5) * 100 + origin.y;
			
			var time:Number = Math.random() * .25 +.5;
			
			var tween:Tween = fly.get(Tween);
			tween.to(fly.get(Spatial), time, {x:targetX, y:targetY, ease:Linear.easeInOut, onComplete:moveFly, onCompleteParams:[fly]});
		}
	}
}