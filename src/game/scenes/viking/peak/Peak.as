package game.scenes.viking.peak
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.hit.Door;
	import game.components.motion.ShakeMotion;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.DuckDown;
	import game.data.animation.entity.character.Place;
	import game.data.animation.entity.character.Salute;
	import game.data.animation.entity.character.Stand;
	import game.scenes.viking.VikingEvents;
	import game.scenes.viking.VikingScene;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.AnimationAction;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.SetSkinAction;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.motion.ShakeMotionSystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.timeline.TimelineVariableSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class Peak extends VikingScene
	{
		private var _events:VikingEvents;
		
		private var rocks:Array;
		
		private var bomb:Entity;
		private var fuse:Entity;
		private var rays:Entity;
		private var lensTarget:Entity;
		
		private var FUSE:String =  SoundManager.EFFECTS_PATH + "lit_fuse_01_L.mp3";
		private var EXPLODE:String = SoundManager.EFFECTS_PATH + "explosion_01.mp3";
		private var CRUMBS:String = SoundManager.EFFECTS_PATH +"explosion_with_debris_01.mp3";
		private var ROPE:String = SoundManager.EFFECTS_PATH + "slide_down_rope_01.mp3";
		private var BAG:String = SoundManager.EFFECTS_PATH + "sand_bag_01.mp3";
		
		
		public function Peak()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/viking/peak/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			addSystem(new ThresholdSystem());
			
			shellApi.eventTriggered.add(handleEventTriggered);
			
			PerformanceUtils.determineAndSetDefaultBitmapQuality();
			
			// setup rock explosion
			if(shellApi.checkEvent(_events.PEAK_EXPLODED)){
				// remove rays+rocks+gunpowder
				_hitContainer.removeChild(_hitContainer["rays"]);
				_hitContainer.removeChild(_hitContainer["fuse"]);
				_hitContainer.removeChild(_hitContainer["bomb"]);
				for (var i:int = 0; null != _hitContainer["boulder"+i]; i++) 
				{
					_hitContainer.removeChild(_hitContainer["boulder"+i]);
				}
				removeEntity(getEntityById("rockInteraction"));
			}
			else{
				// prep rocks
				var clip:MovieClip;
				var rock:Entity;
				rocks = new Array();
				for (var j:int = 0; null != _hitContainer["boulder"+j]; j++) 
				{
					clip = _hitContainer["boulder"+j];
					rock = EntityUtils.createMovingEntity(this, clip);
					rocks.push(rock);	
					if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
						DisplayUtils.bitmapDisplayComponent(rock);
					}
				}
				DisplayUtils.moveToTop(EntityUtils.getDisplayObject(rocks[4]));
				clip = _hitContainer["rays"];
				// sunlight
				rays = EntityUtils.createSpatialEntity(this, clip);	
				// dialog
				var rockInter:Entity = getEntityById("rockInteraction");
				var inter:Interaction = rockInter.get(Interaction);
				inter.click.add(rockComment);
				rockInter.remove(SceneInteraction);
				
				// lens + gun powder stuff
				clip = _hitContainer["bomb"];
				bomb = EntityUtils.createSpatialEntity(this, clip);
				bomb.add(new Id("bomb"));
				if(!shellApi.checkEvent(_events.PLACED_GUNPOWDER)){
					Display(bomb.get(Display)).visible = false;
				}
				else{
					addItemClick(bomb);
				}
				clip = _hitContainer["fuse"];
				if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
					this.addSystem(new TimelineVariableSystem());
					fuse = BitmapTimelineCreator.createBitmapTimeline(clip,true,true,null,PerformanceUtils.defaultBitmapQuality, 18);
					this.addEntity(fuse);
				}
				else{
					fuse = EntityUtils.createMovingTimelineEntity(this, clip, null, false, 18);
				}
				if(!shellApi.checkEvent(_events.PLACED_ROPE)){
					Display(fuse.get(Display)).visible = false;
				}
				else{
					addItemClick(fuse);
				}
				fuse.add(new Id("fuse"));
				
				clip = _hitContainer["lensRay"];
				lensTarget = EntityUtils.createSpatialEntity(this, clip);
				
				if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
					DisplayUtils.bitmapDisplayComponent(rays);
					DisplayUtils.bitmapDisplayComponent(bomb);
					DisplayUtils.bitmapDisplayComponent(lensTarget);
				}
				DisplayUtils.moveToTop(EntityUtils.getDisplayObject(player));
			}
		}
		
		private function rockComment(...p):void
		{
			if(shellApi.checkEvent(_events.PEAK_EXPLODED)){
				Dialog(player.get(Dialog)).sayById("post");
			}else{
				Dialog(player.get(Dialog)).sayById("rocks");
			}
		}
		
		private function handleEventTriggered(event=null,...p):void
		{
			if(event == "use_" + _events.GUNPOWDER){
				CharUtils.moveToTarget(player,EntityUtils.getPosition(bomb).x, EntityUtils.getPosition(bomb).y, false, placeGunpowder, new Point(25,60));
			}
			else if(event == "use_" + _events.ROPE){
				if(shellApi.checkEvent(_events.PLACED_GUNPOWDER)){
					CharUtils.moveToTarget(player,EntityUtils.getPosition(fuse).x, EntityUtils.getPosition(fuse).y, false, placeRope, new Point(25,60));
				}else{
					Dialog(player.get(Dialog)).sayById("nothing");
				}
			}
			else if(event == "use_" + _events.LENS){
				if(!shellApi.checkEvent(_events.PEAK_EXPLODED)){
					if(shellApi.checkEvent(_events.PLACED_ROPE)){
						moveToLens();
					}
					else if(shellApi.checkEvent(_events.PLACED_GUNPOWDER)){
						Dialog(player.get(Dialog)).sayById("lens");
					}
					else{
						Dialog(player.get(Dialog)).sayById("nothing");
					}
				}else{
					Dialog(player.get(Dialog)).sayById("done");
				}
			}
			else if( event == "boom_plz"){
				explodeRocks();
			}
		}
		
		private function placeGunpowder(...p):void
		{
			if(!shellApi.checkEvent(_events.PLACED_GUNPOWDER)){
				//if(EntityUtils.getPosition(player).x < 948 && EntityUtils.getPosition(player).y < 950){
				var actions:ActionChain = new ActionChain(this);
				actions.lockInput = true;
				
				//actions.addAction(new MoveAction(player,EntityUtils.getPosition(bomb), new Point(30,60)));
				actions.addAction(new CallFunctionAction(Command.create(CharUtils.setDirection,player,false)));
				actions.addAction(new AnimationAction(player, Place,"trigger2"));
				actions.addAction(new CallFunctionAction(gunpowderPlaced));
				
				actions.execute();
				//}else{
				// handle too far awayness
				//}
			}
		}	
		
		private function gunpowderPlaced(...p):void
		{
			Display(bomb.get(Display)).visible = true;
			shellApi.removeItem(_events.GUNPOWDER);
			shellApi.completeEvent(_events.PLACED_GUNPOWDER);
			addItemClick(bomb);
			// SOUND
			AudioUtils.playSoundFromEntity(bomb, BAG);
		}
		
		private function placeRope(...p):void
		{
			if(!shellApi.checkEvent(_events.PLACED_ROPE)){
				//if(EntityUtils.getPosition(player).x < 948 && EntityUtils.getPosition(player).y < 950){
				var actions:ActionChain = new ActionChain(this);
				actions.lockInput = true;
				
				//actions.addAction(new MoveAction(player,EntityUtils.getPosition(fuse), new Point(30,60)));
				actions.addAction(new CallFunctionAction(Command.create(CharUtils.setDirection,player,false)));
				actions.addAction(new AnimationAction(player, Place,"trigger2"));
				actions.addAction(new CallFunctionAction(fusePlaced));
				
				actions.execute();
				//}else{
				// handle too far awayness
				//}
			}
		}
		
		private function fusePlaced():void
		{
			Display(fuse.get(Display)).visible = true;
			shellApi.removeItem(_events.ROPE);
			shellApi.completeEvent(_events.PLACED_ROPE);
			addItemClick(fuse);
			// SOUND		
			AudioUtils.playSoundFromEntity(bomb, ROPE);
		}
		
		private function moveToLens():void
		{
			var targ:Point = EntityUtils.getPosition(lensTarget);
			CharUtils.moveToTarget(player, targ.x, targ.y, false, useLens, new Point(25,60));
		}
		
		private function useLens(...p):void
		{
			//if(shellApi.checkEvent(_events.PLACED_GUNPOWDER) && shellApi.checkEvent(_events.PLACED_ROPE)){
			SceneUtil.lockInput(this, true);
			CharUtils.setDirection(player, false);
			player.get(Spatial).x = 760;
			
			var actions:ActionChain = new ActionChain(this);
			
			actions.addAction(new SetSkinAction(player, SkinUtils.ITEM, "comic_lens",false, true));
			actions.addAction(new AnimationAction(player, Salute, "raised", 0, false));
			actions.addAction(new CallFunctionAction(fireBeam));
			
			actions.execute();
			//}else{
			//Dialog(player.get(Dialog)).sayById("lens");
			//}
		}
		
		private function fireBeam():void
		{
			var item:Entity = SkinUtils.getSkinPartEntity(player, SkinUtils.ITEM);
			Timeline(item.get(Timeline)).gotoAndPlay("start");
			Timeline(item.get(Timeline)).handleLabel("mid",lightFuse);
			// SOUND
			
		}
		
		private function lightFuse(...p):void
		{
			var tl:Timeline = fuse.get(Timeline);
			tl.gotoAndPlay("start");
			tl.handleLabel("run", fleeExplosion);
			//tl.handleLabel("end",explodeRocks);
			// SOUND
			AudioUtils.playSoundFromEntity(fuse, FUSE,600, 0.4, 1.1);
		}
		
		private function fleeExplosion(...p):void
		{
			Motion(player.get(Motion)).maxVelocity.x = 200;
			var path:Vector.<Point> = new Vector.<Point>;
			var nav:MovieClip = _hitContainer["runNav0"];
			path.push(new Point(nav.x,nav.y));
			nav = _hitContainer["runNav1"];
			path.push(new Point(nav.x,nav.y));
			CharUtils.followPath(player, path, reachedHide, false, false, new Point(60,80));
			SkinUtils.setSkinPart(player, SkinUtils.ITEM, "empty",true);
		}
		
		private function reachedHide(...p):void
		{
			var charMotion:CharacterMotionControl = player.get(CharacterMotionControl);
			charMotion.spinEnd = true;
			Motion(player.get(Motion)).rotation = 0;
			SceneUtil.addTimedEvent(this, new TimedEvent(1.2,1,triggerPhoto));
			CharUtils.setAnim(player, DuckDown);
		}
		
		private function triggerPhoto(...p):void
		{
			this.shellApi.takePhoto("13479", explodeRocks);
		}
		
		private function explodeRocks( ...p ):void
		{
			// clear lights, bomb, and string
			removeEntity(rays);
			removeEntity(fuse,true);
			removeEntity(bomb);
			
			var motion:Motion;
			var thresh:Threshold;
			for (var i:int = 0; i < rocks.length; i++)
			{
				var driftX:Number = GeomUtils.randomInRange(-150, 150);
				var driftY:Number = GeomUtils.randomInRange(-300, 300);
				motion = rocks[i].get(Motion);
				if(i<=2){
					motion.velocity = new Point(-350 + driftX, -400 + driftY);
					motion.acceleration.y = MotionUtils.GRAVITY;
				}else{
					motion.velocity = new Point(200 + driftX, -350 + driftY);
					motion.acceleration.y = MotionUtils.GRAVITY;
					if(i == 3){
						motion.rotationVelocity = 5;
					}
				}
				thresh = new Threshold("y",">");
				thresh.threshold = 1600;
				thresh.entered.addOnce(Command.create(clearRock,rocks[i]));
				rocks[i].add(thresh);
				Display(rocks[i].get(Display)).moveToFront();
			}
			// SOUND
			AudioUtils.play(this,EXPLODE,1.1,false);
			shakeScreen();
		}
		
		private function shakeScreen():void
		{
			addSystem(new ShakeMotionSystem());
			var cam:Entity = this.getEntityById("camera");
			cam.add(new ShakeMotion(new RectangleZone(-3, -3, 3, 3)));
			cam.add(new SpatialAddition());
			
			SceneUtil.addTimedEvent(this, new TimedEvent(2,1,stopShake));
			//SOUND
			AudioUtils.play(this,CRUMBS,1.1,false);
		}
		
		private function stopShake(...p):void
		{
			this.getEntityById("camera").remove(ShakeMotion);
		}
		
		private function clearRock(rock:Entity):void
		{
			removeEntity(rock,true);
			rocks.splice(rocks.indexOf(rock),1);
			if(rocks.length == 0){
				shellApi.completeEvent(_events.PEAK_EXPLODED);
				SceneUtil.lockInput(this, false);
				Dialog(player.get(Dialog)).sayById("post");
				Dialog(player.get(Dialog)).complete.addOnce(unJam);
				var door:Entity = getEntityById("door1");
				Door(door.get(Door)).data.destinationScene = "game.scenes.viking.waterfall2.Waterfall2";
				//SceneUtil.addTimedEvent(this, new TimedEvent(1.2,1,triggerPhoto));
			}
		}
		
		private function unJam(...p):void
		{
			FSMControl(player.get(FSMControl)).setState(CharacterState.STAND);
			CharUtils.setAnim(player, Stand,false,0,0,false);
			CharUtils.moveToTarget(player, player.get(Spatial).x + 100, player.get(Spatial).y);
		}
		
		private function addItemClick(item:Entity):Interaction
		{
			var interation:Interaction = InteractionCreator.addToEntity(item,[InteractionCreator.CLICK]);
			ToolTipCreator.addToEntity(item);
			interation.click.add(Command.create(examineItem, item));
			return interation;
		}
		
		private function examineItem(pla:Entity, item:Entity):void
		{
			Dialog(player.get(Dialog)).sayById(item.get(Id).id);
		}		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
	}
}