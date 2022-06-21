package game.scenes.survival2.fishingHole
{
	import com.greensock.easing.Expo;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.entity.collider.BitmapCollider;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.PlatformReboundCollider;
	import game.components.entity.collider.SceneCollider;
	import game.components.entity.collider.ZoneCollider;
	import game.components.hit.CurrentHit;
	import game.components.hit.Platform;
	import game.components.hit.Zone;
	import game.components.motion.Edge;
	import game.components.motion.SceneObjectMotion;
	import game.components.motion.Threshold;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.FlipObject;
	import game.data.animation.entity.character.Proud;
	import game.data.animation.entity.character.Push;
	import game.data.animation.entity.character.Stand;
	import game.data.sound.SoundModifier;
	import game.scene.template.ItemGroup;
	import game.scenes.survival1.shared.components.TriggerHit;
	import game.scenes.survival2.Survival2Events;
	import game.scenes.survival2.caughtFish.CaughtFish;
	import game.scenes.survival2.fishingHole.fish.Fishable;
	import game.scenes.survival2.fishingHole.fish.FishableSystem;
	import game.scenes.survival2.shared.Survival2Scene;
	import game.scenes.survival2.shared.components.Hook;
	import game.scenes.survival2.shared.components.Hookable;
	import game.scenes.survival2.shared.flippingRocks.FlipGroup;
	import game.scenes.survival2.shared.flippingRocks.FlippableRock;
	import game.scenes.survival2.shared.systems.HookSystem;
	import game.systems.motion.SceneObjectMotionSystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.Utils;

	
	public class FishingHole extends Survival2Scene
	{
		private const NUM_ICE_CHUNKS:int = 13;
		
		private var _caughtFish:Boolean = false;
		private var _inFishingZone:Boolean = false;
		private var _tree:MovieClip;
		private var _boulder:Entity;
		private var _stone:Entity;
		private var _fishingCommentSaid:Boolean = false;
		
		private var _events:Survival2Events;
		
		public function FishingHole()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/survival2/fishingHole/";
			
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
			
			this.addSystem(new SceneObjectMotionSystem());
			this.addSystem(new ThresholdSystem());
			this.addSystem(new FishableSystem());
			this.addSystem(new WaveMotionSystem());
			
			HookSystem(super.getSystem( HookSystem )).onHookStart.add( onHookStart );
			
			this.setupRedHerring();
			this.setupFish();
			this.setupFishingSpot();
			this.setupStone();
			this.setupTree();
			this.setupBoulder();
			this.setupBoulderZones();
			this.setupBranches();
			this.setupIce();
		}
		
		private function setupRedHerring():void
		{
			var clip:MovieClip = this._hitContainer["redHerring"];
			var herring:Entity = EntityUtils.createSpatialEntity(this, clip);
			
			var hookable:Hookable = new Hookable();
			hookable.bait = "any";
			hookable.remove = true;
			hookable.reeled.add(this.onRedHerringReeled);
			herring.add(hookable);
		}
		
		private function onRedHerringReeled(hookableEntity:Entity, hookEntity:Entity):void
		{
			var dialog:Dialog = this.player.get(Dialog);
			dialog.sayById("redHerring");
		}
		
		private function setupFish():void
		{
			var swimArea:Rectangle = new Rectangle(1775, 980, 530, 120);
			
			for(var i:int = 1; i <= 3; ++i)
			{
				var clip:MovieClip = this._hitContainer["fish" + i];
				this.convertContainer(clip);
				
				var entity:Entity = EntityUtils.createMovingEntity(this, clip);
				
				entity.add(new SpatialAddition());
				entity.add(new Id("fish" + i));
				
				TimelineUtils.convertClip(clip, this, entity, null, true);
				var timeline:Timeline = entity.get(Timeline);
				timeline.gotoAndPlay("swimming");
				
				var wave:WaveMotion = new WaveMotion();
				wave.data.push(new WaveMotionData("y", 10, 0.05));
				entity.add(wave);
				
				entity.add(new Fishable(swimArea));

				var hookable:Hookable = new Hookable();
				hookable.bait = "";
				hookable.remove = true;
				hookable.offsetX = 0;
				hookable.offsetY = 50;
				hookable.wrongBait.add(this.onWrongBait);
				hookable.reeling.add(this.onFishReeling);
				hookable.reeled.add(this.onFishReeled);
				entity.add(hookable);
				
				entity.remove(Sleep);
			}
		}
		
		private function setupFishingSpot():void
		{
			var zone:Zone = this.getEntityById("fishZone").get(Zone);
			zone.entered.add(this.onFishingZoneEntered);
			zone.exitted.add(this.onFishingZoneExitted);
		}
		
		private function onFishingZoneEntered(zoneID:String, colliderID:String):void
		{
			var motion:Motion;
			
			if(colliderID == "player")
			{
				this._inFishingZone = true;
			}
				
			else if(colliderID == "boulder")
			{
				motion 				= _boulder.get( Motion );
				motion.velocity.x   = 800;
			}
		}
		
		private function onFishingZoneExitted(zoneID:String, colliderID:String):void
		{
			if(colliderID == "player")
			{
				this._inFishingZone = false;
			}
		}

		private function onHookStart():void
		{
			_fishingCommentSaid = false;
		}
		
		private function onWrongBait(hookableEntity:Entity, hookEntity:Entity):void
		{
			if( !_fishingCommentSaid )
			{
				var dialog:Dialog = this.player.get(Dialog);
				if(hookEntity.get(Hook).bait != "worms")
				{
					dialog.sayById("wrongBait");
				}
				else if(!this._inFishingZone)
				{
					dialog.sayById("wrongSpot");
				}
				_fishingCommentSaid = true;
			}
		}
		
		private function onFishReeling(hookableEntity:Entity, hookEntity:Entity):void
		{
			SceneUtil.lockInput(this);
			hookableEntity.get(Timeline).gotoAndPlay("caught");
			MotionUtils.zeroMotion(hookableEntity);
			
			var spatial:Spatial = hookableEntity.get(Spatial);
			spatial.rotation = 90;
			if(spatial.scaleX < 0)
			{
				spatial.scaleX *= -1;
			}
		}
		
		private function onFishReeled(hookableEntity:Entity, hookEntity:Entity):void
		{
			SceneUtil.lockInput( this, false );
			if(!this._caughtFish)
			{
				this._caughtFish = true;
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "important_event_02.mp3", 1, false, [SoundModifier.EFFECTS]);
				ItemGroup(super.getGroupById(ItemGroup.GROUP_ID)).showAndGetItem( _events.MEDAL_SURVIVAL2, null, suchFishing );
			}
		}
		
		private function suchFishing():void
		{
			//shellApi.completedIsland();
			CharUtils.setAnim( player, Proud );
			RigAnimation( CharUtils.getRigAnim( player )).ended.addOnce( onCelebrateEnd );
		}
		
		private function onCelebrateEnd( ...args ):void
		{
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, Command.create( shellApi.loadScene, CaughtFish )));
		}
		
		private function setupStone():void
		{
			this.getEntityById("stonePlatform").remove(Platform);
			
			var flipGroup:FlipGroup = new FlipGroup(this, this._hitContainer);
			this.addChildGroup(flipGroup);
			
			this._stone = flipGroup.createFlippingEntity(this._hitContainer["stone"], "flipstone", 5, 2, false);
			var flippable:FlippableRock = this._stone.get(FlippableRock);
			flippable.flipped.add(this.onFlipped);
			onFlipped();
		}
		
		private function onFlipped():void
		{
			var flippable:FlippableRock = this._stone.get(FlippableRock);
			
			if(flippable.currentPosition == 5)
			{
				this.getEntityById("stonePlatform").add(new Platform());
			}
			else
			{
				this.getEntityById("stonePlatform").remove(Platform);
			}
		}
		
		private function setupTree():void
		{
			var treeInteraction:Entity 	= this.getEntityById("treeInteraction");
			this._tree 					= this._hitContainer["tree"];
			this._tree.mouseEnabled 	= false;
			
			//this.removeEntity(this.getEntityById("platformHole"));
			
			if(this.shellApi.checkEvent(this._events.FISHING_HOLE_TREE_PUSHED))
			{
				this._tree.rotation = -36;
				this.removeEntity(this.getEntityById("treeUnpushedPlatform"));
				this.removeEntity(this.getEntityById("platformHole"));
				this.removeEntity(treeInteraction);
			}
			else
			{
				this._tree.rotation = 29;
				this.getEntityById("treePushedPlatform").remove(Platform);
				
				var hole:Entity = this.getEntityById("platformHole");
				var platform:Platform = hole.get(Platform);
				platform.bounce = 0;
				platform.top = true;
				platform.stickToPlatforms = true;
				platform.friction = new Point(500, 500);
				trace("Hole", hole.getAll());
				
				var sceneInteraction:SceneInteraction = treeInteraction.get(SceneInteraction);
				sceneInteraction.offsetX = 50;
				sceneInteraction.reached.addOnce(this.onTreeReached);
			}
		}
		
		private function onTreeReached(player:Entity, interaction:Entity):void
		{
			SceneUtil.lockInput(this);
			CharUtils.setDirection(this.player, false);
			CharUtils.setAnim(this.player, FlipObject);
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "wood_break_05.mp3", 1, false, [SoundModifier.EFFECTS]);
			
			this.shellApi.completeEvent(this._events.FISHING_HOLE_TREE_PUSHED);
			this.getEntityById("treePushedPlatform").add(new Platform());
			this.getEntityById("treePushedPlatform").remove(Sleep)
			this.removeEntity(this.getEntityById("treeUnpushedPlatform"));
			this.removeEntity(this.getEntityById("platformHole"));
			removeEntity(interaction);
			
			var tween:Tween = this.getGroupEntityComponent(Tween);
			tween.to(this._tree, 2, {rotation:-36, ease:Expo.easeIn, onComplete:this.onTreePushed});
		}
		
		private function onTreePushed():void
		{
			SceneUtil.lockInput(this, false);
			CharUtils.setAnim(this.player, Stand);
			CharUtils.stateDrivenOn(this.player);
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "wood_heavy_impact_01.mp3", 1, false, [SoundModifier.EFFECTS]);
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "snow_large_impact_03.mp3", 1, false, [SoundModifier.EFFECTS]);
		}
		
		private function setupBoulder():void
		{
			if(this.shellApi.checkEvent(this._events.ICE_BROKEN))
			{
				this._hitContainer.removeChild(this._hitContainer["boulder"]);
				this.removeEntity(this.getEntityById("boulderInteraction"));
			}
			else
			{
				this._boulder = EntityUtils.createMovingEntity(this, this._hitContainer["boulder"]);
				this._boulder.add(new Edge(-61, -61, 122, 122));
				this._boulder.add(new BitmapCollider());
				this._boulder.add(new SceneCollider());
				this._boulder.add(new CurrentHit());
				this._boulder.add(new ZoneCollider());
				this._boulder.add(new Id("boulder"));
				//this._boulder.add(new PlatformCollider());
				
				var motion:Motion 	= this._boulder.get(Motion);
				motion.friction 	= new Point(0, 0);
				motion.maxVelocity 	= new Point(1000, 1000);
				motion.minVelocity 	= new Point(0, 0);
				motion.acceleration = new Point(0, MotionUtils.GRAVITY);
				motion.restVelocity = 100;
				motion.pause 		= true;
				this._boulder.add(motion);
				
				var sceneObjectMotion:SceneObjectMotion = new SceneObjectMotion();
				sceneObjectMotion.rotateByPlatform = false;
				sceneObjectMotion.rotateByVelocity = true;
				sceneObjectMotion.platformFriction = 10;
				this._boulder.add(sceneObjectMotion);
				
				var platformCollider:PlatformReboundCollider = new PlatformReboundCollider();
				platformCollider.bounce = -0.2;
				//this._boulder.add(platformCollider);
				
				var sceneInteraction:SceneInteraction = this.getEntityById("boulderInteraction").get(SceneInteraction);
				sceneInteraction.approach = false;
				//sceneInteraction.offsetX = -50;
				//sceneInteraction.minTargetDelta = new Point(20, 20);
				sceneInteraction.triggered.add(this.onBoulderTriggered);
			}
		}
		
		private function onBoulderTriggered(player:Entity, boulder:Entity):void
		{
			CharUtils.moveToTarget(this.player, 150, 227, false, this.onBoulderReached, new Point(10, 30));
		}
		
		private function onBoulderReached(player:Entity):void
		{
			SceneUtil.lockInput(this);
			CharUtils.setAnim(this.player, Push);
			CharUtils.setDirection(this.player, true);
			
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, this.onBoulderPushed));
		}
		
		private function onBoulderPushed():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "heavy_gritty_roll_04_loop.mp3", 1, true, [SoundModifier.EFFECTS]);
			
			CharUtils.setAnim(this.player, Stand);
			CharUtils.stateDrivenOn(this.player);
			
			SceneUtil.setCameraTarget(this, this._boulder);
			
			var motion:Motion 	= this._boulder.get(Motion);
			motion.pause 		= false;
			motion.velocity.x 	= 400;
			
			this._boulder.remove(Threshold);
			this._boulder.add(new PlatformCollider());
			
			var platformCollider:PlatformReboundCollider = new PlatformReboundCollider();
			platformCollider.bounce = -0.2;
			this._boulder.add(platformCollider);
			
			var threshold:Threshold = null;
			
			if(!this.shellApi.checkEvent(this._events.FISHING_HOLE_TREE_PUSHED))
			{
				threshold = new Threshold("x", ">=");
				threshold.threshold = 550;
				threshold.entered.add(this.onBoulderIntoTree);
				this._boulder.add(threshold);
			}
			else if(this.getEntityById("stonePlatform").get(Platform))
			{
				/*
				The player has put the stone in the correct place and the tree has been pushed.
				Remove the icePlatform so it doesn't cause the boulder to miss the zone.
				*/
				this.removeEntity(this.getEntityById("icePlatform"));
			}
			else
			{
				threshold = new Threshold("x", ">=");
				threshold.threshold = 1600;
				threshold.entered.add(this.onBoulderIntoHole);
				this._boulder.add(threshold);
			}
		}
		
		private function onBoulderIntoTree():void
		{
			this._boulder.get(Motion).velocity.x = -400;
		}
		
		private function onBoulderIntoHole():void
		{
			this._boulder.get(Motion).velocity.x = -100;
		}
		
		private function setupBoulderZones():void
		{
			var zone:Zone;
			
			zone = this.getEntityById("fallZone").get(Zone);
			zone.entered.add(this.onZoneEntered);
			zone.shapeHit = false;
			zone.pointHit = true;
			
			zone = this.getEntityById("treeZone").get(Zone);
			zone.entered.add(this.onZoneEntered);
			zone.shapeHit = false;
			zone.pointHit = true;
			
			zone = this.getEntityById("iceZone").get(Zone);
			zone.entered.add(this.onZoneEntered);
			zone.shapeHit = false;
			zone.pointHit = true;
		}
		
		private function onZoneEntered(zoneID:String, colliderID:String):void
		{
			var motion:Motion;
			
			if(colliderID == "boulder")
			{
				AudioUtils.stop(this, SoundManager.EFFECTS_PATH + "heavy_gritty_roll_04_loop.mp3");
				
				this._boulder.remove(SceneCollider);
				
				if(zoneID == "iceZone")
				{
					if(!this.shellApi.checkEvent(this._events.ICE_BROKEN))
					{
						AudioUtils.play(this, SoundManager.EFFECTS_PATH + "glass_break_03.mp3", 1, false, [SoundModifier.EFFECTS]);
						
						motion 					= this._boulder.get(Motion);
						motion.velocity.x 		= 40;
						motion.velocity.y 		= 10;
						motion.rotationVelocity = 200;
						
						this.shellApi.completeEvent(this._events.ICE_BROKEN);
						
						DisplayUtils.moveToTop(this._hitContainer["icePatch"]);
						
						for(var i:int = 1; i <= NUM_ICE_CHUNKS; ++i)
						{
							var ice:Entity = EntityUtils.createMovingEntity(this, this._hitContainer["ice" + i]);
							
							var threshold:Threshold = new Threshold("y", ">=");
							threshold.threshold 	= 1150;
							threshold.entered.addOnce(Command.create(this.removeEntity, ice, true));
							ice.add(threshold);
							
							motion 					= ice.get(Motion);
							motion.velocity.y 		= -500;
							motion.velocity.x 		= Utils.randNumInRange(-100, 100);
							motion.rotationVelocity = Utils.randNumInRange(-200, 200);
							motion.acceleration.y 	= MotionUtils.GRAVITY;
						}
						
						SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, this.triggerIceDialog));
					}
					else
					{
						AudioUtils.play(this, SoundManager.EFFECTS_PATH + "water_splash_01.mp3", 1, false, [SoundModifier.EFFECTS]);
						this.resetCameraAndBoulder();
					}
					
				}
				else if(zoneID == "fallZone")
				{
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "water_splash_01.mp3", 1, false, [SoundModifier.EFFECTS]);
					this.resetCameraAndBoulder();
				}
				else if(zoneID == "treeZone")
				{
					AudioUtils.play(this, SoundManager.EFFECTS_PATH + "large_stone_01.mp3", 1, false, [SoundModifier.EFFECTS]);
					this.resetCameraAndBoulder();
				}
			}
		}
		
		private function triggerIceDialog():void
		{
			this.removeEntity(this.getEntityById("boulder"));
			this.removeEntity(this.getEntityById("boulderInteraction"));
			
			SceneUtil.lockInput(this, false);
			SceneUtil.setCameraTarget(this, this.player);
			//resetCameraAndBoulder();
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, this.sayIceDialog ));
		}
		
		private function sayIceDialog():void
		{
			var dialog:Dialog = this.player.get(Dialog);
			dialog._manualSay = "Ice going!";
			
		}
		
		private function resetCameraAndBoulder():void
		{
			SceneUtil.lockInput(this, false);
			SceneUtil.setCameraTarget(this, this.player);
			
			this._boulder.remove(PlatformCollider);
			this._boulder.remove(PlatformReboundCollider);
			
			var spatial:Spatial = this._boulder.get(Spatial);
			spatial.x 			= 18;
			spatial.y 			= 186;
			spatial.rotation 	= -180;
			
			var tween:Tween = this.getGroupEntityComponent(Tween);
			tween.to(spatial, 2, {x:207, y:224, rotation:0, onComplete:this.onBoulderRolled});
			
			var motion:Motion = this._boulder.get(Motion);
			motion.zeroMotion();
			motion.pause = true;
			motion.rotationVelocity = 0;
			motion.rotationAcceleration = 0;
		}
		
		private function onBoulderRolled():void
		{
			this._boulder.add(new SceneCollider());
		}
		
		private function setupBranches():void
		{
			var bounceEntity:Entity;
			var clip:MovieClip;
			var entity:Entity;
			var number:int;
			var timeline:Timeline;
			
			for( number = 1; number < 4; number ++ )
			{
				clip = _hitContainer[ "branch" + number ];
				bounceEntity = getEntityById( "bounce" + number );
				
				entity = EntityUtils.createSpatialEntity( this, clip );
				entity.add( new Id( "branch" + number ));
				TimelineUtils.convertClip( clip, this, entity, null, false );
				
				bounceEntity.add( new TriggerHit( entity.get( Timeline )));
			}
		}
		
		private function setupIce():void
		{
			if(this.shellApi.checkEvent(this._events.ICE_BROKEN))
			{
				DisplayUtils.moveToTop(this._hitContainer["icePatch"]);
				this.removeEntity(this.getEntityById("icePlatform"));
				this.removeEntity(this.getEntityById("iceCeiling"));
				
				for(var i:int = 1; i <= NUM_ICE_CHUNKS; ++i)
				{
					this._hitContainer.removeChild(this._hitContainer["ice" + i]);
				}
			}
		}
	}
}