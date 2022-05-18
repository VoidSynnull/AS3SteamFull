package game.scenes.shrink.kitchenShrunk01
{
	import com.greensock.easing.Bounce;
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
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
	import engine.managers.SoundManager;
	
	import game.components.entity.Children;
	import game.components.entity.Dialog;
	import game.components.entity.collider.HazardCollider;
	import game.components.entity.collider.PlatformCollider;
	import game.components.entity.collider.PlatformReboundCollider;
	import game.components.entity.collider.RectangularCollider;
	import game.components.entity.collider.SceneCollider;
	import game.components.entity.collider.SceneObjectCollider;
	import game.components.entity.collider.ZoneCollider;
	import game.components.hit.CurrentHit;
	import game.components.hit.Hazard;
	import game.components.hit.HitTest;
	import game.components.hit.Platform;
	import game.components.hit.SceneObjectHit;
	import game.components.hit.ValidHit;
	import game.components.hit.Zone;
	import game.components.motion.FollowTarget;
	import game.components.motion.Mass;
	import game.components.motion.SceneObjectMotion;
	import game.components.scene.SceneInteraction;
	import game.creators.entity.EmitterCreator;
	import game.creators.motion.SceneObjectCreator;
	import game.creators.scene.HitCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.scene.hit.HazardHitData;
	import game.data.scene.hit.HitType;
	import game.data.sound.SoundModifier;
	import game.data.sound.SoundType;
	import game.particles.emitter.WaterStream;
	import game.scenes.shrink.kitchenShrunk01.components.Plug;
	import game.scenes.shrink.kitchenShrunk01.components.Spatula;
	import game.scenes.shrink.kitchenShrunk01.systems.PlugSystem;
	import game.scenes.shrink.kitchenShrunk01.systems.SpatulaSystem;
	import game.scenes.shrink.shared.Systems.CarrySystem.Carry;
	import game.scenes.shrink.shared.Systems.PressSystem.Press;
	import game.scenes.shrink.shared.Systems.PressSystem.PressSystem;
	import game.scenes.shrink.shared.groups.GrapeGroup;
	import game.scenes.shrink.shared.groups.ShrinkScene;
	import game.systems.SystemPriorities;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.hit.HazardHitSystem;
	import game.systems.hit.HitTestSystem;
	import game.systems.hit.SceneObjectHitRectSystem;
	import game.systems.hit.ZoneHitSystem;
	import game.systems.motion.FollowTargetSystem;
	import game.systems.motion.SceneObjectMotionSystem;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	public class KitchenShrunk01 extends ShrinkScene
	{
		public function KitchenShrunk01()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/shrink/kitchenShrunk01/";
			
			super.init(container);
		}
		
		private var _sceneObjectCreator:SceneObjectCreator;
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			_sceneObjectCreator = new SceneObjectCreator();
			this.addSystem(new SceneObjectHitRectSystem());
			this.addSystem(new SceneObjectMotionSystem(), SystemPriorities.moveComplete);
			this.addSystem(new FollowTargetSystem(), SystemPriorities.update);
			this.addSystem(new PlugSystem(carryGroup), SystemPriorities.lowest);
			player.add(new SceneObjectCollider());
			player.add(new RectangularCollider());
			player.add(new Mass(100));
			
			setupToaster();
			setupFaucet();
			setupPlug();
			setUpSpatula();
			setUpSponge();
			setUpIceMaker();
			setUpTrash();
		}
		
		private function setUpTrash():void
		{
			var door:Entity = getEntityById("doorTrashCan");
			var interaction:SceneInteraction = door.get(SceneInteraction);
			interaction.validCharStates = new <String>[CharacterState.STAND];
		}
		
		private function setUpIceMaker():void
		{
			var iceMaker:Entity = getEntityById("iceMaker");
			iceMaker.add(new HitTest(jumpOnIceMaker));
		}
		
		private function jumpOnIceMaker(...args):void
		{
			var remoteControl:Entity = getEntityById( shrink.REMOTE_CONTROL );
			if(remoteControl != null)
			{
				SceneUtil.lockInput(this);
				SceneUtil.setCameraTarget(this, remoteControl);
				SceneUtil.delay(this, 2, commentOnControl)
			}
		}
		
		private function commentOnControl():void
		{
			SceneUtil.setCameraTarget(this, player);
			var dialog:Dialog = player.get(Dialog);
			dialog.sayById("look_remote");
			dialog.complete.addOnce(returnControls);
		}
		
		private function returnControls(...args):void
		{
			SceneUtil.lockInput(this, false);
		}
		
		private function setUpSponge():void
		{
			var clip:MovieClip = _hitContainer["sponge"];
			var sponge:Entity = _sceneObjectCreator.createBox(clip, 0, _hitContainer, NaN, NaN, null, null, sceneData.bounds, this,null,null,200);
		}
		
		private function setUpSpatula():void
		{
			var clip:MovieClip = _hitContainer["spatula"];
			if(PlatformUtils.isMobileOS)
				convertContainer(clip, PerformanceUtils.defaultBitmapQuality);
			var spatula:Entity = EntityUtils.createMovingEntity(this, clip, _hitContainer).add(new Id(clip.name));
			
			var handle:Entity = getEntityById("spatulaHandle");
			Display(handle.get(Display)).isStatic = false;
			setUpFollow(handle, spatula);
			handle.add(new HitTest(null, false, sprungFromHandle));
			var zone:Zone = new Zone();
			zone.pointHit = true;
			zone.entered.add(forceSaltUp);
			handle.add(zone);
			
			var head:Entity = getEntityById("spatulaHead");
			Display(head.get(Display)).isStatic = false;
			setUpFollow(head, spatula);
			head.add(new HitTest());
			
			// going the full rotation makes it so that the player sticks to the platform beneath
			// so adding the - 5 as a buffer to prevent this.
			// amplification adds the extra oomf you need to make the jump from what velocity you can actually produce
			spatula.add(new Spatula(handle.get(HitTest), head.get(HitTest), -Spatial(head.get(Spatial)).rotation - 5, 1.66));
			// changing the spatulas trajectory from realistic to game play required.
			Spatula(spatula.get(Spatula)).headTrajectory = new Point(-.75,-1);
			
			clip = _hitContainer["saltShaker"];
			if(PlatformUtils.isMobileOS)
				convertContainer(clip, PerformanceUtils.defaultBitmapQuality);
			
			// eventually the salt is going to be used to project the player, but until pushing comes along i just use the grape
			var salt:Entity = _sceneObjectCreator.createBox(clip, 0, _hitContainer, NaN, NaN, null, null, new Rectangle(1500, 250, 650, 500), this,null,null,200);
			salt.add(new Id(clip.name));
			salt.add(new ZoneCollider());
			Motion(salt.get(Motion)).friction = new Point(10000, 0);
			addSystem(new SpatulaSystem(),SystemPriorities.moveComplete);
			addSystem(new ZoneHitSystem());
		}
		
		private function sprungFromHandle(handle:Entity, hitId:String):void
		{
			Motion(getEntityById(hitId).get(Motion)).acceleration.y = MotionUtils.GRAVITY;
		}
		
		private function forceSaltUp(zoneId:String, hitId:String):void
		{
			if(hitId == "saltShaker")// making it so the salt doesnt run off on yeah
			{
				var salt:Entity = getEntityById(hitId);
				Spatial(salt.get(Spatial)).y -= 25;
				Spatial(salt.get(Spatial)).x -= 25;
				salt.remove(SceneObjectMotion);
				salt.remove(SceneCollider);
				salt.remove(SceneObjectHit);
				salt.remove(PlatformReboundCollider);
				salt.add(new PlatformCollider());
				MotionUtils.zeroMotion(salt);
			}
		}
		
		private function setUpFollow(follower:Entity, target:Entity):void
		{
			var followSpatial:Spatial = follower.get(Spatial);
			var targetSpatial:Spatial = target.get(Spatial);
			var follow:FollowTarget = new FollowTarget(targetSpatial, 1, false, true);
			follow.offset = new Point(followSpatial.x - targetSpatial.x, followSpatial.y - targetSpatial.y);
			follow.rotationOffSet = followSpatial.rotation;
			follow.properties = new <String>["x","y","rotation"];
			follower.add(follow);
		}
		
		override public function setUpGrape():void
		{
			grapeGroup = new GrapeGroup(_hitContainer, this) as GrapeGroup;
			grapeGroup.pickUpDropGrape.add(checkGrapeState);
			grapeGroup.grapeSetUp.add(grapeSetUp);
			addChildGroup(grapeGroup);
		}
		
		private function grapeSetUp(grape:Entity):void
		{
			var validHits:ValidHit = new ValidHit("handle");
			validHits.inverse = true;
			grape.add(validHits);
		}
		
		private function checkGrapeState(holdingGrape:Boolean):void
		{
			var press:Press = _handle.get(Press);
			if(HitTest(_handle.get(HitTest)).isHitting("player"))
			{
				if(press.atTop)
					press.locked = !holdingGrape;
				else
					press.locked = !_pluggedIn;
			}
			
			var carry:Carry = _plugEntity.get(Carry);
			if(carry.holding && holdingGrape)
			{
				carryGroup.dropItem(_plugEntity, player);
				SceneInteraction(_plugEntity.get(SceneInteraction)).reached.dispatch(player, _plugEntity);
			}
		}
		
		private function setupToaster():void
		{
			this.convertToBitmap(this._hitContainer["toaster"]);
			var heat:MovieClip = this._hitContainer["heat"];
			_toasterHeat = EntityUtils.createSpatialEntity(this, heat);
			Display(_toasterHeat.get(Display)).alpha = 0;
			
			_handle = getEntityById("handle");
			Display(_handle.get(Display)).isStatic = false;
			EntityUtils.visible(_handle);
			
			var press:Press = new Press(new Point(1050, 1100),_handle, 100, 400,false, false, 3, 10);
			press.pressed.add(heatUpToaster);
			
			_handle.add(new HitTest(hitHandle, false, leaveHandle)).add(press).add(new Motion());
			Platform(_handle.get(Platform)).stickToPlatforms = true;
			
			addSystem(new HitTestSystem());
			addSystem(new PressSystem());
		}
		
		private function leaveHandle(handle:Entity, hitId:String):void
		{
			if(hitId == "player")
				Press(handle.get(Press)).locked = false;
		}
		
		private function hitHandle(handle:Entity, hitId:String):void
		{
			if(hitId == "player")
				Press(handle.get(Press)).locked = !shellApi.checkEvent( shrink.HAS_GRAPE);
		}
		
		private function heatUpToaster(entity:Entity):void
		{
			var press:Press = entity.get(Press);
			
			if(press.locked)
			{
				if(CurrentHit(player.get(CurrentHit)).hit == press.hitNode.entity)
					Dialog(player.get(Dialog)).sayById("not_enough_weight");
				return;
			}
			
			if(_pluggedIn)
			{
				press.forceRelease = true;
				press.time = 0;
				press.released.addOnce(shootPlayerUp);
				turnOnHeat(press.autoReleaseTime);
			}
		}
		
		private function turnOnHeat(duration:Number):void
		{
			TweenUtils.globalFromTo(this, EntityUtils.getDisplay(_toasterHeat), duration, {alpha:0}, {alpha:1}, "toasterHeat");
		}
		
		private function shootPlayerUp(entity:Entity):void
		{
			var press:Press = entity.get(Press);
			Display(_toasterHeat.get(Display)).alpha = 0;
			if(HitTest(_handle.get(HitTest)).isHitting("player"))
			{
				shellApi.triggerEvent("toasterHandleLaunch");
				Motion(player.get(Motion)).velocity.y = -1200;
				if(grapeGroup.holdingGrape)
					grapeGroup.dropGrape();
			}
		}
		
		private function setupFaucet():void
		{
			var hotHandle:Entity = this.getEntityById("handle2Interaction");
			var coldHandle:Entity = this.getEntityById("handle1Interaction");
			
			hotHandle.get(Display).isStatic = false;
			coldHandle.get(Display).isStatic = false;
			
			hotHandle.get(SceneInteraction).reached.add(handleClicked);
			coldHandle.get(SceneInteraction).reached.add(handleClicked);
			
			_waterStream = new WaterStream();
			_waterStream.init(new Rectangle(-20, 0, 40, 80), 30, 14, 0x3399CC, .28);
			
			var waterFaucet:Entity = EntityUtils.createSpatialEntity(this, this._hitContainer["faucet"]);
			waterFaucet.add(new Audio()).add(new AudioRange(1000, 0,1,Quad.easeOut)).add(new Id("waterFaucet"));
			EmitterCreator.create(this, _hitContainer["faucet"], _waterStream, 0, 0,waterFaucet, null, null, false);
		}
		
		private function handleClicked(char:Entity, handle:Entity):void
		{
			shellApi.triggerEvent("sinkHandleTurn");
			var spatial:Spatial = handle.get(Spatial);
			
			if(spatial.scaleX == 1)
			{
				TweenUtils.globalTo(this, spatial, .5, {scaleX:.45}, "handleMove");
				
				if(handle.get(Id).id == "handle2Interaction")
					_hotOn = true;
				else
					_coldOn = true;
				
				checkFaucetWater();
			}
			else
			{
				TweenUtils.globalTo(this, spatial, .5, {scaleX:1, onComplete:checkFaucetWater}, "handleMoveBack");
				
				if(handle.get(Id).id == "handle2Interaction")
					_hotOn = false;
				else
					_coldOn = false;
			}
		}
		
		private const WATER_FAUCET:String = SoundManager.EFFECTS_PATH+"water_fountain_large_01_loop.mp3";
		
		private function checkFaucetWater():void
		{
			var faucet:Entity = getEntityById("waterFaucet");
			var audio:Audio = faucet.get(Audio);
			if(!_hotOn && !_coldOn)
			{
				_waterStream.counter.stop();
				audio.stop(WATER_FAUCET, SoundType.EFFECTS);
			}
			else
			{
				audio.play(WATER_FAUCET, true, SoundModifier.POSITION);
				_waterStream.start();
			}
		}
		
		private function setupPlug():void
		{
			addSystem(new HazardHitSystem());
			var shockText:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["shock"], _hitContainer);
			var shockSpatial:Spatial = shockText.get(Spatial);
			shockSpatial.scaleX = shockSpatial.scaleY = 0;
			
			var socket:Entity = getEntityById("socketInteraction");
			var sceneInt:SceneInteraction = new SceneInteraction();
			sceneInt.minTargetDelta = new Point(25, 80);
			sceneInt.reached.add(socketReached);
			socket.add(sceneInt);
			ToolTipCreator.removeFromEntity(socket);
			ToolTipCreator.addToEntity(socket, "click", null, new Point(0, -20));
			
			_plugEntity = this.getEntityById("plugInteraction");
			Display(_plugEntity.get(Display)).isStatic = false;
			carryGroup.makeEntityCarryable(this, _plugEntity);
			
			var plug:Plug = new Plug();
			plug.cord = _hitContainer[ "cord" ];
			plug.follow = this.player;
			plug.socket = socket;
			plug.goodZone = new Rectangle(1750, 1020, 355, 172);
			plug.shockEntity = shockText;
			_plugEntity.add(plug);
			
			_shockOriginalX = shockText.get(Spatial).x;			
			Carry(_plugEntity.get(Carry)).pickUpDropItem.add(pickUpPlug);
		}
		
		private function socketReached(interactor:Entity, socket:Entity):void
		{
			var plug:Plug = _plugEntity.get(Plug);
			var plugSpatial:Spatial = _plugEntity.get(Spatial);
			var display:Display = _plugEntity.get(Display);
			var cord:MovieClip = plug.cord;
			
			// Plug in the plug and then kill this system
			if(plug.holdingPlug)
			{
				plug.holdingPlug = false;
				carryGroup.dropItem(_plugEntity, plug.follow);
				shellApi.triggerEvent("pluggedIn");
				_pluggedIn = true;
				
				var socketSpatial:Spatial = socket.get(Spatial);
				plugSpatial.x = socketSpatial.x;
				plugSpatial.y = socketSpatial.y - 40;
				MotionUtils.zeroMotion(_plugEntity);
				
				cord.graphics.clear();
				cord.graphics.lineStyle(10, 0x393A33, 1);
				cord.graphics.curveTo((plugSpatial.x - cord.x)/2, 20, plugSpatial.x - cord.x, plugSpatial.y - cord.y);
				
				DisplayUtils.moveToOverUnder( plug.follow.get(Display).displayObject, display.displayObject, true );
				DisplayUtils.moveToOverUnder( cord, display.displayObject, true );
				
				// Remove the interactions from the plug
				_plugEntity.remove(Interaction);
				_plugEntity.remove(SceneInteraction);
				
				removeEntity(_plugEntity.get(Children).children[0]);
				removeEntity(socket);
				removeSystemByClass(PlugSystem);
				
				DisplayUtils.moveToOverUnder( display.displayObject, plug.follow.get(Display).displayObject, false );
				DisplayUtils.moveToOverUnder( plug.cord, display.displayObject, true );
			}
			else
			{
				// Initate the shock
				var hitX:Number = 200;
				var shockX:Number = 40;
				
				if(interactor.get(Spatial).x < socket.get(Spatial).x)
				{
					shockX *= -1;
				}
				
				// force hit
				var hitCreator:HitCreator = new HitCreator();
				var hitData:HazardHitData = new HazardHitData();
				hitData.type = "shock";
				hitData.knockBackCoolDown = .75;
				hitData.knockBackVelocity = new Point(hitX, 600);
				hitData.velocityByHitAngle = false;
				hitCreator.makeHit(socket, HitType.HAZARD, hitData, this);
				
				shellApi.triggerEvent("zapped");
				plug.shockEntity.get(Spatial).x += shockX;
				DisplayUtils.moveToTop(plug.shockEntity.get(Display).displayObject);
				TweenUtils.globalFromTo(this, plug.shockEntity.get(Spatial), .25, {scaleX:.6, scaleY:.6}, {scaleX:1.2, scaleY:1.2, ease:Bounce.easeInOut, onComplete:shockOverLarge, onCompleteParams:[plug.shockEntity, socket]});
			}
		}
		
		private function shockOverLarge(entity:Entity, socket:Entity = null):void
		{
			if(socket)
			{
				socket.remove(Hazard);
			}
			
			TweenUtils.globalTo(this, entity.get(Spatial), .25, {scaleX:.6, scaleY:.6, ease:Bounce.easeInOut, onComplete:shockInMiddle, onCompleteParams:[entity]});
		}
		
		private function shockInMiddle(entity:Entity):void
		{
			TweenUtils.globalTo(this, entity.get(Spatial), .25, {scaleX:1, scaleY:1, ease:Bounce.easeInOut, onComplete:shockDone, onCompleteParams:[entity]});
		}
		
		private function shockDone(entity:Entity):void
		{
			_plugEntity.remove(Hazard);
			TweenUtils.globalTo(this, entity.get(Spatial), .15, {scaleX:0, scaleY:0, x:_shockOriginalX}, "shockOut", .2);
		}
		
		private function pickUpPlug(plug:Entity, pickUp:Boolean):void
		{
			if(pickUp)
			{
				if(grapeGroup.holdingGrape)
					grapeGroup.dropGrape();
			}
		}
		
		
		// Plug
		private var _plugEntity:Entity;
		private var _pluggedIn:Boolean = false;
		private var _shockOriginalX:Number;
		
		// Toaster
		private var _handle:Entity;
		private var _toasterHeat:Entity;
		
		// Faucet
		private var _waterStream:WaterStream;
		private var _hotOn:Boolean = false;
		private var _coldOn:Boolean = false;
	}
}