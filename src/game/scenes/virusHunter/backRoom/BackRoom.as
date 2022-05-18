package game.scenes.virusHunter.backRoom{
	
	import com.greensock.TimelineMax;
	import com.greensock.TweenLite;
	import com.greensock.TweenMax;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.components.hit.Zone;
	import game.creators.entity.EmitterCreator;
	import game.data.animation.entity.character.KeyboardTyping;
	import game.scene.SceneSound;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.scenes.virusHunter.backRoom.particles.ShrinkParticles;
	import game.scenes.virusHunter.bloodStream.BloodStream;
	import game.scenes.virusHunter.joesCondo.JoesCondo;
	import game.scenes.virusHunter.shipTutorial.ShipTutorial;
	import game.ui.popup.Popup;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	
	public class BackRoom extends PlatformerGameScene
	{
		public function BackRoom()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/virusHunter/backRoom/";
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
			
			isMember = super.shellApi.profileManager.active.isMember;
			
			_lange = super.getEntityById("npc");
			
			//var laserMount:MovieClip = super._hitContainer["laserMount"];
			var shrinkRay:MovieClip = super._hitContainer["shrinkRay"];
			//var tubes:MovieClip = super._hitContainer["tubes"];
			//Performance is too slow with tubes. Not worth it. -Jordan
			
			//convertToBMC(laserMount);
			_shrinkRayBMC = convertToBMC(shrinkRay);
			//_tubesBMC = convertToBMC(tubes);
			
			super._hitContainer["laserBeam"].visible = false;
			super._hitContainer["laserEffect"].visible = false;
			
			var bg:Entity = super.getEntityById("background");
			_bg = Display(bg.get(Display)).displayObject;
			_hl = super._hitContainer;
			
			var fg:Entity = super.getEntityById("foreground");
			_fg = Display(fg.get(Display)).displayObject;
			
			var virusEvents:VirusHunterEvents = new VirusHunterEvents();
			
			if (super.shellApi.checkEvent( virusEvents.ENTERED_JOE )) {
				super.removeEntity(_lange);
				if (!super.shellApi.checkHasItem(virusEvents.MEDAL_VIRUS)) {
					//they are supposed to be in the body. load the bloodStream
					super.shellApi.loadScene(BloodStream,0,0);
				}
			}
			else if (super.shellApi.checkEvent( virusEvents.COMPLETED_TUTORIAL )) {
				SceneUtil.lockInput(this, true);
				var interaction:Interaction = _lange.get(Interaction);
				interaction.click.dispatch(_lange);
			}
			else {
				initParticles();
				
				var zoneHitEntity:Entity = super.getEntityById("zoneHit");
				var zoneHit:Zone = zoneHitEntity.get(Zone);
				
				zoneHit.entered.add(handleZoneEntered);
				zoneHit.exitted.add(handleZoneExitted);
				zoneHit.inside.add(handleZoneInside);
				zoneHit.shapeHit = false;
				zoneHit.pointHit = true;
				
				var startInt:Interaction = _lange.get(Interaction);
				startInt.click.add(startConversation);
			}
			
			
			
			//_particleEmitter.startGas();
			
			//redAlert();
			//prepFire();
			//fire();
			
			// events
			super.shellApi.eventTriggered.add(handleEventTriggered);
		}
		
		private function handleZoneEntered(zoneId:String, characterId:String):void
		{
			if(_padReady){
				//if (isMember) {
					_inZone = true;
					SceneUtil.lockInput(this, true);
					CharUtils.lockControls(super.player);
					CharUtils.moveToTarget(super.player, 217, 736, true, reachedTarget);
				//}
				//else {
					//showBlocker();
				//}
			}
		}
		
		private function handleZoneExitted(zoneId:String, characterId:String):void
		{
			_inZone = false;
		}
		
		private function handleZoneInside(zoneId:String, characterId:String):void
		{
			
		}
		
		private function reachedTarget($entity:Entity):void{
			if(_reachedPad == false){
				CharUtils.setDirection(super.player, true);
				_timer = new Timer(2000, 1);
				_timer.addEventListener(TimerEvent.TIMER_COMPLETE, startSequence);
				_timer.start();
				_reachedPad = true;
			}
		}
		
		private function startSequence($event:TimerEvent):void{
			trace("START SEQUENCE "+_timer);
			_timer.removeEventListener(TimerEvent.TIMER_COMPLETE, startSequence); // gc
			_timer.stop();
			_timer = null;
			
			//toggleBMC(_tubesBMC);
			//_tubesBMC.mc.play();
			
			SceneUtil.setCameraTarget(this, _lange);
			
			redAlert();
			super.shellApi.triggerEvent("startSequence");
			CharUtils.setAnim(_lange, KeyboardTyping, false );
		}
		
		private function convertToBMC(mc:MovieClip):Object{
			/**
			 * Converts the movieclip into a "BMC" which is a
			 * bitmap-movieclip pair wrapped in an object.
			 * This function the mc will be replaced by a drawn bitmap duplicate.
			 * 
			 * by calling toggleBMC({}), one can toggle to show the MC version or the BMP version
			 */
			var mcBMPD:BitmapData = new BitmapData(mc.width, mc.height, true, 0x000000);
			var mcBMP:Bitmap = new Bitmap(mcBMPD, "auto", false);
			mcBMPD.draw(mc);
			
			mc.visible = false;
			
			mcBMP.x = mc.x;
			mcBMP.y = mc.y;
			
			mc.parent.addChild(mcBMP); // add bitmap to mc's parent
			
			mc.parent.swapChildren(mc, mcBMP); // swap depths
			
			return {bitmap:mcBMP, mc:mc};
		}
		
		private function toggleBMC($object:Object):void{
			$object.mc.parent.swapChildren($object.bitmap, $object.mc);
			$object.bitmap.visible = false;
			$object.mc.visible = true;
		}
		
		private function showPopup():void
		{
			var popup:BlueprintPopup = super.addChildGroup(new BlueprintPopup(super.overlayContainer)) as BlueprintPopup;
			popup.id = "blueprintPopup";
			
			popup.bpFound.addOnce(handleBPFound);
			
			function handleBPFound():void{
				popup.removed.addOnce(foundBP);
			}
		}
		
		private function foundBP(popup:BlueprintPopup):void{
			// handle remainder of BP actions
			super.shellApi.triggerEvent("foundBP");
		}
		
		private function redAlert():void{
			// tones scene to in a flashing red
			if(_timeLine){
				//_timeLine.stop();
				_timeLine.clear();
			} else {
				_timeLine = new TimelineMax({repeat:-1, repeatDelay:0.5});
			}
			
			_timeLine.appendMultiple(TweenMax.allTo([_bg, _hl, _fg], 1, {colorMatrixFilter:{colorize:0xff0000, amount:0.8}}, 0.1));
			_timeLine.appendMultiple(TweenMax.allTo([_bg, _hl, _fg], 1, {colorMatrixFilter:{}}, 0.1));
			//_timeLine.append(new TweenMax(_bg, 1, {colorMatrixFilter:{colorize:0xff0000, amount:1}}));
			//_timeLine.append(new TweenMax(_bg, 1, {colorMatrixFilter:{}}));
		}
		
		private function prepFire():void{
			_timeLine.clear();
			_timeLine = new TimelineMax();
			
			_timeLine.appendMultiple(TweenMax.allTo([_bg], 9, {colorMatrixFilter:{colorize:0x3300FF, amount:0.7}}, 0.1));
			_timeLine.insertMultiple(TweenMax.allTo([_hl, _fg], 9, {colorMatrixFilter:{colorize:0x33CCFF, amount:0.3}}, 0.1));
		}
		
		private function fire($event:TimerEvent):void{
			_shrinkRayBMC = convertToBMC(_shrinkRayBMC.mc);
			
			super._hitContainer.swapChildren(super._hitContainer["laserEffect"], Display(super.player.get(Display)).displayObject);
			
			_timer.removeEventListener(TimerEvent.TIMER_COMPLETE, fire);
			super._hitContainer["laserBeam"].visible = true;
			super._hitContainer["laserEffect"].visible = true;
			_particleEmitter.startGas();
			// strobes scene in flashes of blue light
			_timeLine.clear();
			_timeLine = new TimelineMax({repeat:-1, yoyo:true});
			
			TweenMax.to(_fg, 0.5, {colorMatrixFilter:{colorize:0x330000, amount:0.8}});
			_timeLine.appendMultiple(TweenMax.allTo([_bg, _hl], 0.025, {colorMatrixFilter:{colorize:0x3300FF, contrast:3, amount:1}}, 0.012));
			_timeLine.appendMultiple(TweenMax.allTo([_bg, _hl], 0.025, {colorMatrixFilter:{colorize:0x33FFFF, amount:1}}, 0.012));
			
			super.shellApi.triggerEvent("beamFired");
		}
		
		private function initParticles():void{
			var group:Group = this;
			var container:DisplayObjectContainer = super._hitContainer;
			_particleEmitter = new ShrinkParticles();
			_particleEmitter.init();
			
			var basicEmitter:Entity = EmitterCreator.create( group, container, _particleEmitter, 236, 846 );
			
		}
		
		private function finishShrink():void{
			_particleEmitter.stopGas();
			
			_timeLine.clear();
			_timeLine = new TimelineMax();
			
			_timeLine.appendMultiple(TweenMax.allTo([_bg, _hl], 2, {colorMatrixFilter:{}}));
			_timeLine.appendMultiple(TweenMax.allTo([_bg, _hl, _fg], 3, {colorMatrixFilter:{colorize:0x000000, amount:1}, onComplete:startShipTutorial}));
		}
		
		private function startShipTutorial():void{
			super.shellApi.loadScene(ShipTutorial,1000,500);
		}
		
		private function startConversation(entity:Entity):void
		{
			SceneUtil.lockInput(this, true);
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			switch(event){
				case "showPopup":
					showPopup();
					break;
				case "padReady":
					SceneUtil.lockInput(this, false);
					_padReady = true;
					break;
				case "startSequence2":
					//_tubesBMC = convertToBMC(_tubesBMC.mc);
					SceneUtil.setCameraTarget(this, super.player);
					break;
				case "startSequence3":
					SceneUtil.setCameraTarget(this, _lange);
					break;
				case "startSequence4":
					toggleBMC(_shrinkRayBMC);
					_shrinkRayBMC.mc.device.play();
					break;
				case "startSequence5":
					prepFire();
					SceneUtil.setCameraTarget(this, super.player);
					break;
				case "startSequence6":
					SceneUtil.setCameraTarget(this, _lange);
					break;
				case "startSequence7":
					SceneUtil.setCameraTarget(this, super.player);
					_timer = new Timer(1000, 1);
					_timer.addEventListener(TimerEvent.TIMER_COMPLETE, fire);
					_timer.start();
					break;
				case "beamFired2":
					// shrink player
					//trace(super.player.getAll());
					var playerHeight:Number = Spatial(super.player.get(Spatial)).height;
					var downMove:Number = playerHeight + Spatial(super.player.get(Spatial)).y;
					TweenLite.to(Spatial(super.player.get(Spatial)), 3, {scale:0.01});
					break;
				case "beamFired4":
					// stop beam sequence
					finishShrink();
					super._hitContainer["laserBeam"].visible = false;
					super._hitContainer["laserEffect"].visible = false;
					var sceneSoundEntity:Entity = super.getEntityById(SceneSound.SCENE_SOUND);
					var sceneAudio:Audio = sceneSoundEntity.get(Audio);
					sceneAudio.stop("weapon_laser_blade_hum_1_L.mp3");
					break;
				case "loadJoesCondo":
					//show "later that evening..." then load joesCondo
					super.shellApi.loadScene(JoesCondo,0,0);
					break;
			}
		}
		
		/*
		private function showBlocker(arg:*=null):void {
			var blocker:IslandBlockPopup = addChildGroup(new IslandBlockPopup(overlayContainer)) as IslandBlockPopup;
			blocker.id = 'nonMemberBlockPopup';
			blocker.popupRemoved.addOnce(reloadScene);
		}
		*/
		
		private function reloadScene(popup:Popup=null):void {
			//removing during testing period, so progress isn't blocked
			super.shellApi.loadScene(BackRoom);
		}
		
		private var _reachedPad:Boolean = false;
		
		private var _lange:Entity; // dr. lange's entity
		private var _timer:Timer;
		private var _padReady:Boolean = false; // after you have talked to lange - pad will be serviceable
		private var _inZone:Boolean = false;
		
		private var _bg:DisplayObject; // background
		private var _hl:DisplayObject; // hit layer
		private var _fg:DisplayObject; // foreground
		
		private var _particleEmitter:ShrinkParticles;
		
		private var _shrinkRayBMC:Object;
		//private var _tubesBMC:Object;
		private var _timeLine:TimelineMax;
		private var isMember:Boolean;
	}
}