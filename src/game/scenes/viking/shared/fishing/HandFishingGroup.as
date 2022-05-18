package game.scenes.viking.shared.fishing
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.group.Scene;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.entity.OriginPoint;
	import game.components.entity.Sleep;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.motion.FollowTarget;
	import game.components.motion.Threshold;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.AnimationSlotCreator;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.Read;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.viking.VikingEvents;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.AudioAction;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.TalkAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.systems.entity.EyeSystem;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.motion.ThresholdSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TweenUtils;
	
	public class HandFishingGroup extends Group
	{
		public static const GROUP_ID:String = "HandFishingGroup";
		
		private var _container:DisplayObjectContainer;
		private var player:Entity;
		private var _events:VikingEvents;
		private var gobletOut:Boolean = false;	
		private var holdingFish:Boolean = false;
		private var fishList:Array;
		
		private var GRAB:String = SoundManager.EFFECTS_PATH + "fs_under_water_swirl_01.mp3";
		private var DROP:String = SoundManager.EFFECTS_PATH + "fs_under_water_swirl_02.mp3"; // DROP THE BASS, yea...
		private var POP_SOUND:String = SoundManager.EFFECTS_PATH + "pop_03.mp3";
		
		public function HandFishingGroup(container:DisplayObjectContainer)
		{
			this.id = GROUP_ID;
			_container = container;		
		}
		
		override public function added():void
		{
			player = PlatformerGameScene(this.parent).player;
			shellApi = parent.shellApi;
			setupFishing();
			
			shellApi.eventTriggered.add(handleEventTriggered);
			
			super.added();
		}
		
		private function handleEventTriggered(event=null,...p):void
		{
			if(event == "use_" + _events.GOBLET){
				// equip goblet, allow fish capture
				if(!shellApi.checkEvent(_events.CAUGHT_FISH) && !gobletOut){
					Dialog(player.get(Dialog)).sayById("equip_goblet");
					SkinUtils.setSkinPart(player,SkinUtils.ITEM, "comic_goblet", false);
					gobletOut = true;
				}
				else if(shellApi.checkEvent(_events.CAUGHT_FISH)){
					Dialog(player.get(Dialog)).sayById("has_fish");
				}
				else{
					SkinUtils.setSkinPart(player,SkinUtils.ITEM, "empty", true);
					gobletOut = false;
				}
			}
			else if(event == _events.CAUGHT_FISH){
				// lock other fish?
			}
		}
		
		// fish idles/swims, click to grab, wiggles while grabbed, then runs away, resumes idle/swim
		private function setupFishing():void
		{
			this.addSystem( new FishStateSystem());
			this.addSystem( new ThresholdSystem());
			
			fishList = new Array();
			var clip:MovieClip;
			var fish:Entity;
			var bitSeq:BitmapSequence = BitmapTimelineCreator.createSequence(_container["fish"+0],true,PerformanceUtils.defaultBitmapQuality);
			for (var i:int = 0; _container["fish"+i]; i++) 
			{
				clip = _container["fish"+i];
				if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
					fish = BitmapTimelineCreator.createBitmapTimeline(clip, true, true, bitSeq, PerformanceUtils.defaultBitmapQuality);
					fish.add(new Motion());
					this.addEntity(fish);
				}
				else{
					fish = EntityUtils.createMovingTimelineEntity(this, clip, _container);
				}
				fish.add(new Sleep(false, true));
				fishList.push(fish);
				var fishComp:Fish = new Fish();
				fishComp.timeElapsed = GeomUtils.randomInRange(0, fishComp.idleTime-0.1);
				fish.add(fishComp);
				var thresh:Threshold = new Threshold("x");
				fish.add(thresh);
				// start anim
				Timeline(fish.get(Timeline)).gotoAndPlay("idle");				
				// interactions
				var inter:Interaction = InteractionCreator.addToEntity(fish,[InteractionCreator.CLICK]);
				var sceneInt:SceneInteraction = new SceneInteraction();
				sceneInt.minTargetDelta = new Point(35,60);
				fish.add(sceneInt);
				ToolTipCreator.addToEntity(fish);
				sceneInt.reached.addOnce(reachedFish);
				fish.add(new OriginPoint(clip.x, clip.y, clip.rotation));
				MotionUtils.addWaveMotion(fish, new WaveMotionData("y", 6, 0.05),this);
			}
		}
		
		// grab fish out of water like a bear!
		private function reachedFish(p:Entity, fish:Entity):void
		{
			if(!shellApi.checkEvent(_events.CAUGHT_FISH) && !holdingFish){
				holdingFish = true;
				SceneUtil.lockInput(this,true);
				CharUtils.lockControls( player );
				MotionUtils.zeroMotion(player);
				
				fish.remove(WaveMotion);
				
				Fish(fish.get(Fish)).setState(Fish.FLOP);
				
				var rigAnim:RigAnimation = CharUtils.getRigAnim(player, 1);
				if(rigAnim == null)
				{
					var animationSlot:Entity = AnimationSlotCreator.create(player);
					rigAnim = animationSlot.get(RigAnimation) as RigAnimation;
				}
				rigAnim.next = Read;
				rigAnim.addParts(CharUtils.HAND_FRONT, CharUtils.HAND_BACK);
				SceneUtil.addTimedEvent(this,new TimedEvent(0.4,1,Command.create(grabFish, fish)));
			}else{
				Dialog(player.get(Dialog)).sayById("has_fish");
			}
		}
		
		private function grabFish(fish:Entity):void
		{
			EntityUtils.removeAllWordBalloons(this);
			var actions:ActionChain = new ActionChain(Scene(this.parent));
			actions.addAction(new CallFunctionAction(Command.create(holdFish,fish)));
			actions.addAction(new WaitAction(1.2));
			
			if(shellApi.checkHasItem(_events.GOBLET) && gobletOut){
				actions.addAction(new AudioAction(player, POP_SOUND, 800, 1.1, 1.1));	
				actions.addAction(new CallFunctionAction(Command.create(SkinUtils.setSkinPart,player,SkinUtils.ITEM, "comic_goblet_fish",false)));	
				actions.addAction(new CallFunctionAction(Command.create(removeEntity,fish)));
				actions.addAction(new TalkAction(player,"catch_fish"));
				actions.addAction(new CallFunctionAction(Command.create(getFish,fish)));
			}
			else{
				// fish escapes
				actions.addAction(new CallFunctionAction(Command.create(fishEscapes,fish)));
				// flip player backwards
				actions.addAction(new CallFunctionAction(Command.create(hurtPlayer,fish)));
				actions.addAction(new WaitAction(1.6));
				actions.addAction(new TalkAction(player,"need_goblet"));
			}
			actions.addAction(new CallFunctionAction(Command.create(SceneUtil.lockInput,this,false)));
			actions.addAction(new CallFunctionAction(Command.create(CharUtils.lockControls, player, false, false)));			
			actions.execute();
		}
		
		private function getFish(fish:Entity):void
		{
			// get item
			//removeEntity(fish);
			SkinUtils.emptySkinPart(player, SkinUtils.ITEM,true);
			var rigAnim:RigAnimation = CharUtils.getRigAnim(player, 1);
			rigAnim.manualEnd = true;
			shellApi.completeEvent(_events.CAUGHT_FISH);
			shellApi.showItem(_events.GOBLET, null);
			holdingFish = false;
		}		
		
		private function holdFish(fish:Entity):void
		{
			// rotate fish sideways and move to front of player
			var playerloc:Spatial = player.get(Spatial);
			var fishTarg:Point;
			var offset:Point;
			var rot:Number = 0;
			offset = new Point(45, 0);
			
			if(playerloc.scaleX > 0){
				fishTarg = new Point(playerloc.x - 40,playerloc.y-10);
				rot = -45;
			}
			else{
				//offset = new Point(50, 0);
				fishTarg = new Point(playerloc.x + 40,playerloc.y-10);
				rot = 45;
			}
			TweenUtils.entityTo(fish, Spatial, 0.8, {x:fishTarg.x, y:fishTarg.y, rotation:rot, onComplete:Command.create(stickFish,fish,offset)});
			Fish(fish.get(Fish)).setState(Fish.FLOP);
			// SOUND
			AudioUtils.playSoundFromEntity(fish, GRAB);
		}
		
		private function stickFish(fish:Entity, offset:Point):void
		{
			var follow:FollowTarget = new FollowTarget(player.get(Spatial),0.7);
			follow.offset = offset;
			//follow.accountForRotation = true;
			follow.allowXFlip = true;
			fish.add(follow);
			holdingFish = true;
		}
		
		private function fishEscapes(fish:Entity):void
		{		
			fish.remove(FollowTarget);
			var rigAnim:RigAnimation = CharUtils.getRigAnim(player, 1);
			rigAnim.manualEnd = true;
			Timeline(fish.get(Timeline)).gotoAndPlay("swim");
			MotionUtils.addWaveMotion(fish, new WaveMotionData("y", 6, 0.05),this);
			
			var fishTarg:Point = EntityUtils.getPosition(fish);
			var playerloc:Spatial = player.get(Spatial);
			var spatial:Spatial = fish.get(Spatial);
			if(playerloc.scaleX > 0){
				fishTarg.x -= 100;
				spatial.scaleX = 1;
			}
			else{
				fishTarg.x += 100;
				spatial.scaleX = -1;
			}
			fishTarg.y = fish.get(OriginPoint).y;
			holdingFish = false;
			
			TweenUtils.entityTo(fish, Spatial, 1.3, {x:fishTarg.x, y:fishTarg.y, rotation:0, onComplete:delayFishReturn, onCompleteParams:[fish]});
			// SOUND
			AudioUtils.playSoundFromEntity(fish, DROP);
		}
		
		private function hurtPlayer(fish:Entity):void
		{
			var spatial:Spatial = fish.get(Spatial);
			var hitX:Number = spatial.x
			var hitY:Number = spatial.y;
			var motion:Motion = player.get(Motion);
			var deltaX:Number = motion.x - hitX;
			var deltaY:Number = motion.y - hitY;
			var angle:Number = Math.atan2(deltaY, deltaX);
			var baseVelocity:Number = 220;
			
			motion.velocity.x = Math.cos(angle) * baseVelocity;
			motion.velocity.y = Math.sin(angle) * baseVelocity;
			
			FSMControl(player.get(FSMControl)).setState(CharacterState.HURT);
			
			SceneUtil.addTimedEvent(this, new TimedEvent(0.8,1,unHurt));
		}
		
		private function unHurt():void
		{
			player.get(FSMControl).setState(CharacterState.STAND);
			SkinUtils.setEyeStates(player, EyeSystem.STANDARD);
		}
		
		private function delayFishReturn(fish:Entity):void
		{
			Timeline(fish.get(Timeline)).gotoAndPlay("idle");
			SceneUtil.addTimedEvent(this, new TimedEvent(4,1,Command.create(fishReturns,fish)));
		}
		
		private function fishReturns(fish:Entity):void
		{
			// set timed return to initial location
			var target:OriginPoint = fish.get(OriginPoint);
			var spatial:Spatial = fish.get(Spatial);
			//face fish in direction of swim
			if(target.x < spatial.x){
				spatial.scaleX = 1;
			}
			else{
				spatial.scaleX = -1;
			}
			Timeline(fish.get(Timeline)).gotoAndPlay("swim");
			var speed:Number = Fish(fish.get(Fish)).speed;
			var time:Number = GeomUtils.dist(target.x,target.y, spatial.x, spatial.y) / speed;
			TweenUtils.entityTo( fish, Spatial, time, {x:target.x, y:target.y, rotation:target.rotation, onComplete:fishReset, onCompleteParams:[fish]});
		}
		
		private function fishReset(fish:Entity):void
		{
			var sceneInt:SceneInteraction = fish.get(SceneInteraction);
			if(!sceneInt){
				sceneInt = new SceneInteraction();
				fish.add(sceneInt);
			}
			sceneInt.reached.removeAll();
			sceneInt.reached.addOnce(reachedFish);
			Fish(fish.get(Fish)).setState(Fish.IDLE);
		}
		
		
		
		
		
		
		
		
		
		
	}
}