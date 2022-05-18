package game.scenes.survival5.traps
{
	import com.greensock.easing.Bounce;
	import com.greensock.easing.Quad;
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Sleep;
	import game.components.entity.character.Npc;
	import game.components.hit.Item;
	import game.components.hit.Platform;
	import game.components.hit.ValidHit;
	import game.components.hit.Zone;
	import game.components.motion.ShakeMotion;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Knock;
	import game.data.animation.entity.character.Push;
	import game.data.animation.entity.character.Stand;
	import game.data.sound.SoundModifier;
	import game.data.specialAbility.islands.survival.Fishing;
	import game.scenes.survival2.shared.flippingRocks.FlipGroup;
	import game.scenes.survival5.Survival5Events;
	import game.scenes.survival5.shared.Survival5Scene;
	import game.scenes.survival5.shared.whistle.ListenerData;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.motion.ShakeMotionSystem;
	import game.ui.elements.DialogPicturePopup;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class Traps extends Survival5Scene
	{
		public function Traps()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/survival5/traps/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		private var survival:Survival5Events;
		
		// all assets ready
		override public function loaded():void
		{
			if(shellApi.checkEvent(survival.ISLAND_INCOMPLETE))
				whistleListeners.push(new ListenerData("dog", caughtByDog));
			super.loaded();
			
			survival = events as Survival5Events;
			
			setUpRocks();
			setUpTreeBridge();
			setUpDog();
			setUpBear();
			setUpWaterFall();
		}
		
		private function setUpWaterFall():void
		{
			var clip:MovieClip = _hitContainer["fallAnim"];
			BitmapUtils.convertContainer(clip);
			
			var entity:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			TimelineUtils.convertAllClips(clip, entity, this);
			DisplayUtils.moveToBack(clip);
			entity.add(new Audio()).add(new AudioRange(750, 0, 1, Quad.easeIn));
			Audio(entity.get(Audio)).play(SoundManager.EFFECTS_PATH + "water_fountain_01_loop.mp3", true, SoundModifier.POSITION);
		}
		
		override protected function onEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			super.onEventTriggered(event, save, init, removeEvent);
			if(event == Fishing.CAST_LINE)
			{
				var hook:Entity = getEntityById(Fishing.FISHING_HOOK);
				ValidHit(hook.get(ValidHit)).setHitValidState("dogPath", false);
			}
		}
		
		private var _cutFree:Boolean;
		private var _bear:Entity;
		private var dogPath:Vector.<Point>;
		
		private function setUpBear():void
		{
			addSystem(new ShakeMotionSystem());
			_cutFree = false;
			
			var rope:Entity = getEntityById("ropeInteraction");
			var bearZone:Entity = getEntityById("bearZone");
			var clip:MovieClip = _hitContainer["bear"];
			var ropeClip:MovieClip = _hitContainer["ropeFall"];
			
			if(shellApi.checkEvent(survival.RELEASED_BEAR))
			{
				_hitContainer.removeChild(clip);
				_hitContainer.removeChild(ropeClip);
				removeEntity(rope);
				removeEntity(bearZone);
				return;
			}
			
			var ropeItem:Entity = getEntityById("rope");
			EntityUtils.visible(ropeItem, false);
			ToolTipCreator.removeFromEntity(ropeItem);
			ropeItem.remove(Item);
			
			SceneInteraction(rope.get(SceneInteraction)).reached.add(untieBear);
			var interaction:SceneInteraction = rope.get(SceneInteraction);
			interaction.minTargetDelta = new Point(50, 100);
			
			BitmapUtils.convertContainer(clip);
			_bear = EntityUtils.createSpatialEntity(this, clip);
			TimelineUtils.convertClip(clip, this, _bear);
			_bear.add(new Id(clip.name)).remove(Sleep);
			var time:Timeline = _bear.get(Timeline);
			time.handleLabel("thrashEnd", Command.create(stopThrashing, time), false);
			time.handleLabel("thrash", thrash, false);
			time.handleLabel("fall", fall);
			
			var fallRope:Entity = EntityUtils.createSpatialEntity(this, ropeClip);
			BitmapTimelineCreator.convertToBitmapTimeline(fallRope, ropeClip);
			fallRope.add(new Id("ropeFall"));
			Timeline(fallRope.get(Timeline)).gotoAndStop(0);
			EntityUtils.visible(fallRope, false);
			
			var range:AudioRange = new AudioRange(1500, 0 , 1, Quad.easeIn);
			bearZone.add(new Audio()).add(range);
			var zone:Zone = bearZone.get(Zone);
			zone.entered.add(getWrecked);
			zone.pointHit = true;
		}
		
		private function fall():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "rope_snap_01.mp3");
			var rope:Entity = getEntityById("ropeFall");
			EntityUtils.visible(rope);
			var time:Timeline = rope.get(Timeline);
			time.handleLabel("ending", Command.create(removeRope, time))
			time.play();
		}
		
		private function removeRope(time:Timeline):void
		{
			time.gotoAndStop(time.currentIndex);
			removeEntity(getEntityById("ropeFall"), true);
		}
		
		private function stopThrashing(timeline:Timeline):void
		{
			if(_cutFree)
			{
				timeline.handleLabel("ending", Command.create(bearFell, timeline));
				return;
			}
			timeline.gotoAndPlay("hang");
		}
		
		private function bearFell(timeline:Timeline):void
		{
			thrash();
			timeline.gotoAndStop(timeline.currentIndex);
			
			removeEntity(getEntityById("ropeInteraction"));
			removeEntity(getEntityById("bearZone"));
			
			removeEntity(_bear, true);
			
			shakeScreen();
		}
		
		private function shakeScreen():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "snow_large_impact_01.mp3");
			
			var camera:Entity = getEntityById("camera");
			
			var shake:ShakeMotion = new ShakeMotion(new RectangleZone(-5,-5,5,5));
			shake.active = true;
			
			camera.add(shake).add(new SpatialAddition());
			
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, stopShake));
		}
		
		private function stopShake():void
		{
			var camera:Entity = getEntityById("camera");
			camera.remove(ShakeMotion);
			var addition:SpatialAddition = camera.get(SpatialAddition);
			addition.x = addition.y = 0;
			shellApi.completeEvent(survival.RELEASED_BEAR);
			SceneUtil.lockInput(this, false);
			
			var ropeItem:Entity = getEntityById("rope");
			EntityUtils.visible(ropeItem, true);
			ToolTipCreator.addToEntity(ropeItem);
			ropeItem.add(new Item());
		}
		
		private function getWrecked(...args):void
		{
			Timeline(_bear.get(Timeline)).gotoAndPlay("thrash");
			lockControls();
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, openBearPopup));
		}
		
		private function openBearPopup():void
		{
			SceneUtil.lockInput(this, false);
			var popup:DialogPicturePopup = new DialogPicturePopup(overlayContainer);
			popup.configData("bearPopup.swf", groupPrefix);
			popup.updateText("The bear got you! You'll need to find a different way around.", "TRY AGAIN");
			popup.popupRemoved.addOnce( reloadScene );
			addChildGroup(popup);
		}
		
		private function thrash():void
		{
			Audio(getEntityById("bearZone").get(Audio)).play(SoundManager.EFFECTS_PATH + "bear_roar_01.mp3",false, SoundModifier.POSITION);
		}
		
		private function untieBear(player:Entity, click:Entity):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "rope_strain_01.mp3");
			CharUtils.setAnimSequence(player, new <Class>[Knock, Knock, Knock]);
			SceneUtil.lockInput(this);
			_cutFree = true;
			
			player.get(Spatial).x = click.get(Spatial).x + 25;
			
			Timeline(_bear.get(Timeline)).gotoAndPlay("thrash");
		}
		
		private var dog:Entity;
		private const FALL_ROTATION:Number = -75;
		
		private function setUpDog():void
		{
			var validHit:ValidHit = new ValidHit("dogPath");
			validHit.inverse = true;
			player.add(validHit);
			
			if(!shellApi.checkEvent(survival.ISLAND_INCOMPLETE))
				return
				
			dog = getEntityById("dog");
			
			Npc(dog.get(Npc)).ignoreDepth = true;
			DisplayUtils.moveToOverUnder(EntityUtils.getDisplayObject(dog), _hitContainer["flip2"], false);
			dogPath = new <Point>[new Point(1100, 1600), new Point(2100, 1500)];
			
			dog.add( new AudioRange( 600, 0, 1, Sine.easeIn ));
			_audioGroup.addAudioToEntity( dog );
			var audio:Audio = dog.get( Audio );
			audio.playCurrentAction( "random" );
			patrol();
		}
		
		override public function goBackToBusiness(entity:Entity):void
		{
			patrol();
		}
		
		private function patrol():void
		{
			CharUtils.followPath(dog, dogPath, null, true, true);
		}
		
		private function setUpTreeBridge():void
		{
			var clip:MovieClip = _hitContainer["treeTip"];
			var tree:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			tree.add(new Id(clip.name));
			clip = _hitContainer["tipTree"];
			if(!shellApi.checkEvent(survival.TREE_TIPPED))
			{
				getEntityById("treeBridge").remove(Platform);
				var entity:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
				var interaction:SceneInteraction = new SceneInteraction();
				entity.add(new Id(clip.name)).add(interaction);
				
				InteractionCreator.addToEntity(entity, ["click"], clip);
				interaction.reached.add(pushTree);
				interaction.validCharStates = new <String>[CharacterState.STAND];
				ToolTipCreator.addToEntity(entity);
			}
			else
			{
				_hitContainer.removeChild(clip);
				Spatial(tree.get(Spatial)).rotation = FALL_ROTATION;
			}
		}
		
		private function pushTree(player:Entity, entity:Entity):void
		{
			lockControls();
			CharUtils.setAnim(player, Push);
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, tipTree));
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "wood_break_06.mp3");
		}
		
		private var bounceTime:Number;
		
		private function tipTree():void
		{
			TweenUtils.entityTo(getEntityById("treeTip"), Spatial, 2, {rotation:FALL_ROTATION, ease:Bounce.easeOut, onComplete:treeTipped});
			CharUtils.setAnim(player, Stand);
			bounceTime = .8;
			SceneUtil.delay(this, bounceTime, bounce);
		}
		
		private function bounce():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "explosion_01.mp3",bounceTime +.2);
			bounceTime -= .2;
			
			if(bounceTime > .1)
				SceneUtil.delay(this, bounceTime, bounce);
		}
		
		private function treeTipped():void
		{
			getEntityById("treeBridge").add(new Platform());
			removeEntity(getEntityById("tipTree"));
			shellApi.completeEvent(survival.TREE_TIPPED);
			returnControls();
		}
		
		private function setUpRocks():void
		{
			var flippingRocks:FlipGroup = addChildGroup(new FlipGroup(this, _hitContainer)) as FlipGroup;
			var rocks:uint = 3;
			var position:int = 4;
			var flips:int = 4;
			for(var i:int = 1; i <= rocks; i++)
			{
				if(i == 1)
				{
					position = 4;
					flips = 4;
				}
				if(i == 2)
				{
					position = 2;
					flips = 7;
				}
				if(i == 3)
				{
					position = 2;
					flips = 3;
				}
				var clip:MovieClip = _hitContainer["flip"+i];
				var rock:Entity = flippingRocks.createFlippingEntity(clip, "flipstone",flips,position,true,i,true);
			}
		}
		
		private function lockControls(...args):void
		{
			SceneUtil.lockInput(this);
		}
		
		private function returnControls(...args):void
		{
			SceneUtil.lockInput(this, false);
			FSMControl(player.get(FSMControl)).active = true;
		}
	}
}