package game.scenes.survival5.waterEdge
{
	import com.greensock.easing.Quad;
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	
	import game.components.entity.NPCDetector;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.Npc;
	import game.components.hit.Hazard;
	import game.components.hit.SeeSaw;
	import game.components.hit.Zone;
	import game.components.motion.Edge;
	import game.components.motion.Mass;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.scene.HitCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Place;
	import game.data.animation.entity.character.Tremble;
	import game.data.scene.hit.HazardHitData;
	import game.data.scene.hit.HitType;
	import game.data.sound.SoundModifier;
	import game.scenes.survival1.shared.components.TriggerHit;
	import game.scenes.survival1.shared.systems.TriggerHitSystem;
	import game.scenes.survival5.shared.Survival5Scene;
	import game.scenes.survival5.shared.whistle.ListenerData;
	import game.systems.SystemPriorities;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.hit.SeeSawSystem;
	import game.ui.elements.DialogPicturePopup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class WaterEdge extends Survival5Scene
	
	{
		private var currBranchTrap:Number;
		private var hitCreator:HitCreator;
		
		private var dogPath:Vector.<Point>;
		private var dog:Entity;
		private var cage:Entity;
		private var beaver:Entity;
		private var beaverAnim:Entity;
		private var beaverSwimming:Boolean = false;
		private var noDog:Boolean = false;
		
		public function WaterEdge()
		{
			super();
			whistleListeners.push(new ListenerData("dog", caughtByDog));
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/survival5/waterEdge/";
			
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
			//PlatformUtils.forceMobile = true;
			createSeeSaw();
			setupBranches(this._hitContainer["branch0"]);
			setupBranches(this._hitContainer["branch1"]);
			setupBranches(this._hitContainer["branch2"]);
			setupTraps();
			setupBranchTraps();
			configureZones();
			setupBeaver();
			setupWaterfall();
			if(!shellApi.checkEvent("gotItem_medal_survival5")){
				setUpDog();
			}else{
				noDog = true;
			}
		}
		
		private function setupWaterfall():void
		{
			//positional waterfall sound
			var entity:Entity = new Entity();
			var audio:Audio = new Audio();
			audio.play(SoundManager.AMBIENT_PATH + "waterfall_01_loop.mp3", true, [SoundModifier.POSITION, SoundModifier.EFFECTS])
			entity.add(audio);
			entity.add(new Spatial(3299, 1500));
			entity.add(new AudioRange(2000, 0, 0.8, Quad.easeIn));
			entity.add(new Id("soundSource"));
			super.addEntity(entity);
			if( PlatformUtils.isMobileOS )
			{
				var i:uint;
				for(i=1;i<=28;i++){
					_hitContainer.removeChild(_hitContainer["w"+i]);
				}
			}
		}
		
		private function setupBeaver():void {
			var clip:MovieClip = _hitContainer["cage"];
			cage = new Entity();
			cage.add(new Display(clip));
			cage.add(new Spatial(clip.x, clip.y));
			super.addEntity(cage);
			BitmapTimelineCreator.convertToBitmapTimeline(cage);
			
			var cageInt:Entity = getEntityById("cageInteraction");
			
			if(!shellApi.checkEvent(_events.RELEASED_BEAVER)) {
				var cageInteraction:SceneInteraction = cageInt.get( SceneInteraction );	
				cageInteraction.reached.add(waitForMoveToCage);
				
				beaver = EntityUtils.createSpatialEntity(this, _hitContainer["beaver"], _hitContainer);
				//beaverAnim = TimelineUtils.convertAllClips(_hitContainer["beaver"], beaver, this, true);
				BitmapTimelineCreator.convertToBitmapTimeline(beaver);
				beaver.add(new Tween());
				beaver.get(Timeline).handleLabel("running", moveBeaver, true);
				
				shakeBeaver();
				
			}else{
				cageInt.remove(SceneInteraction);
				ToolTipCreator.removeFromEntity( cageInt );
				cageInt.get(Display).displayObject.mouseEnabled = false;
				cageInt.get(Display).displayObject.mouseChildren = false;
				
				cage.get(Timeline).gotoAndStop("end");
				
				var b:MovieClip = _hitContainer["beaver"];
				_hitContainer.removeChild(b);
			}
		}
		
		private function shakeBeaver():void{
			beaver.get(Spatial).x = 2784;
			var targetX:Number = 2785;
			beaver.get(Tween).to(beaver.get(Spatial), .01, { x:targetX, yoyo:true, repeat:2000, onComplete:shakeBeaver });
		}
		
		
		private function waitForMoveToCage(...args):void {
			SceneUtil.addTimedEvent(this, new TimedEvent(.5, 1, moveToCage, true));
		}
		
		private function moveToCage(...args):void {
			SceneUtil.lockInput( this, true );
			CharUtils.moveToTarget(player, 2692, 1640, false, prepareMoveToCage);
		}
		
		private function prepareMoveToCage(entity:Entity=null):void {
			SceneUtil.addTimedEvent(this, new TimedEvent(.25, 1, openCage, true));
		}
		
		private function openCage(entity:Entity=null):void {
			CharUtils.lockControls( player );
			//SceneUtil.lockInput( this, true );
			var motion:Motion = player.get(Motion);
			motion.rotationAcceleration = motion.rotationVelocity = motion.previousRotation = 0;
			MotionUtils.zeroMotion(player);
			player.get(Motion).velocity.x = 0;
			player.get(Motion).velocity.y = 0;
			player.get(CharacterMotionControl).spinning = false;
			
			player.get(Spatial).x = 2692;
			player.get(Spatial).y = 1650;
			
			CharUtils.setState(player, "stand");
			CharUtils.setDirection(player, true);
			CharUtils.setAnim(player, Place, false);
			
			cage.get(Timeline).play();
			beaver.get(Timeline).gotoAndPlay("openCage");
			var cageInt:Entity = getEntityById("cageInteraction");
			cageInt.remove(SceneInteraction);
			ToolTipCreator.removeFromEntity( cageInt );
			cageInt.get(Display).displayObject.mouseEnabled = false;
			cageInt.get(Display).displayObject.mouseChildren = false;
			
			//super.shellApi.triggerEvent("freeBeaverSound");
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "gears_15_loop.mp3");
			SceneUtil.addTimedEvent(this, new TimedEvent(.7, 1, stopBeaverSound, true));
			beaver.get(Tween).killAll();
			player.get(Spatial).rotation = 0;
		}
		
		private function stopBeaverSound():void {
			player.get(Spatial).rotation = 0;
			AudioUtils.stop(this, SoundManager.EFFECTS_PATH + "gears_15_loop.mp3");
		}
		
		private function moveBeaver():void {
			player.get(Spatial).rotation = 0;
			beaver.get(Tween).to(beaver.get(Spatial), 3, { x:3668, ease:Sine.easeInOut, onComplete:getGear, onUpdate:manageBeaver });
		}
		
		private function manageBeaver():void {
			var s:Spatial = beaver.get(Spatial);
			if(s.x > 2900){
				if(!beaverSwimming){
					beaverSwimming = true;
					beaver.get(Timeline).gotoAndPlay("startswim");
				}
				if(s.y < 1896){
					s.y += 5;
				}
			}
		}
		
		private function getGear():void {
			this.removeEntity( beaver );
			super.shellApi.getItem( _events.GEAR, null, true, beaverSequenceComplete );
			cage.get(Timeline).gotoAndStop("noGear");
		}
		
		private function beaverSequenceComplete(...args):void {
			shellApi.completeEvent(_events.RELEASED_BEAVER);
			SceneUtil.lockInput( this, false );
			CharUtils.lockControls( player, false, false );
		}
		
		private function setUpDog():void
		{
			dog = getEntityById("dog");
			
			if(dog != null)
			{
				Npc(dog.get(Npc)).ignoreDepth = true;
				Display(dog.get(Display)).moveToFront();
				dogPath = new <Point>[new Point(1523, 992), new Point(2317, 890)];
				
				dog.add( new AudioRange( 600, 0, 1, Sine.easeIn ));
				_audioGroup.addAudioToEntity( dog );
				var audio:Audio = dog.get( Audio );
				audio.playCurrentAction( "random" );
				patrol();
			}
		}
		
		override public function goBackToBusiness(entity:Entity):void
		{
			patrol();
		}
		
		private function patrol():void
		{
			CharUtils.followPath(dog, dogPath, null, true, true);
		}
		
		private function setupTraps():void {
			var trapArray:Array = ["netTrap1", "netTrap2", "netTrap3"];
			var bitSequence:BitmapSequence;
			var clip:MovieClip;
			var entity:Entity;
			for(var i:uint=0;i<trapArray.length;i++){
				
				if(i==0){
					clip = _hitContainer[trapArray[i]];
					entity = new Entity();
					entity.add(new Display(clip));
					entity.add(new Spatial(clip.x, clip.y));
					entity.add(new Id(trapArray[i]));
					super.addEntity(entity);
					BitmapTimelineCreator.convertToBitmapTimeline(entity);
					bitSequence = entity.get(BitmapSequence);
				}else{
					clip = _hitContainer[trapArray[i]];
					entity = new Entity();
					entity.add(new Display(clip));
					entity.add(new Id(trapArray[i]));
					super.addEntity(entity);
					BitmapTimelineCreator.convertToBitmapTimeline(entity, null, true, bitSequence);
				}
				
				entity.get(Timeline).gotoAndStop(0);
				entity.get(Display).moveToFront();
			}
		}
		
		private function setupBranchTraps():void {
			var trapArray:Array = ["branchTrap1", "branchTrap2", "branchTrap3"];
			var bitSequence:BitmapSequence;
			var clip:MovieClip;
			var entity:Entity;
			var bitSequence2:BitmapSequence;
			var clip2:MovieClip;
			var entity2:Entity;
		
			for(var i:uint=0;i<trapArray.length;i++){
				if(i==0){
					clip = _hitContainer[trapArray[i]]["tree"];
					entity = new Entity();
					entity.add(new Display(clip));
					entity.add(new Spatial(clip.x, clip.y));
					entity.add(new Id(trapArray[i]+"_tree"));
					super.addEntity(entity);
					BitmapTimelineCreator.convertToBitmapTimeline(entity);
					bitSequence = entity.get(BitmapSequence);
					
					clip2 = _hitContainer[trapArray[i]]["rope"];
					entity2 = new Entity();
					entity2.add(new Display(clip2));
					entity2.add(new Spatial(clip2.x, clip2.y));
					entity2.add(new Id(trapArray[i]+"_rope"));
					super.addEntity(entity2);
					BitmapTimelineCreator.convertToBitmapTimeline(entity2);
					bitSequence2 = entity2.get(BitmapSequence);
				}else{
					clip = _hitContainer[trapArray[i]]["tree"];
					entity = new Entity();
					entity.add(new Display(clip));
					entity.add(new Id(trapArray[i]+"_tree"));
					super.addEntity(entity);
					BitmapTimelineCreator.convertToBitmapTimeline(entity, null, true, bitSequence);
					
					clip2 = _hitContainer[trapArray[i]]["rope"];
					entity2 = new Entity();
					entity2.add(new Display(clip2));
					entity2.add(new Id(trapArray[i]+"_rope"));
					super.addEntity(entity2);
					BitmapTimelineCreator.convertToBitmapTimeline(entity2, null, true, bitSequence2);
				}
				
				entity.get(Timeline).gotoAndStop(0);
				entity2.get(Display).alpha = 0;
				entity2.get(Timeline).gotoAndStop(0);
				
				entity.get(Timeline).handleLabel("hitPlayer", trapHitPlayer, true);
				entity.get(Timeline).handleLabel("end", runRope, true);
			}
		}
		
		private function trapHitPlayer():void {
			switch(currBranchTrap) {
				case 1:
					var hazardHitData:HazardHitData = new HazardHitData();
					hazardHitData.knockBackCoolDown = .75;
					hazardHitData.knockBackVelocity = new Point(-800, 800);
					hazardHitData.velocityByHitAngle = false;
					
					var hazHitEntity1:Entity = hitCreator.createHit(super._hitContainer["branchHaz1"], HitType.HAZARD, hazardHitData, this);
					break;
				case 2:
					var hazardHitData2:HazardHitData = new HazardHitData();
					hazardHitData2.knockBackCoolDown = .75;
					hazardHitData2.knockBackVelocity = new Point(1200, 1200);
					hazardHitData2.velocityByHitAngle = false;
					
					var hazHitEntity2:Entity = hitCreator.createHit(super._hitContainer["branchHaz2"], HitType.HAZARD, hazardHitData2, this);
					break;
				case 3:
					var hazardHitData3:HazardHitData = new HazardHitData();
					hazardHitData3.knockBackCoolDown = .75;
					hazardHitData3.knockBackVelocity = new Point(1200, 1200);
					hazardHitData3.velocityByHitAngle = false;
					
					var hazHitEntity3:Entity = hitCreator.createHit(super._hitContainer["branchHaz3"], HitType.HAZARD, hazardHitData3, this);
					break;
			}
		}
		
		private function runRope():void {
			super.getEntityById("branchHaz"+currBranchTrap).remove(Hazard);
			super.getEntityById("branchTrap"+currBranchTrap+"_rope").get(Display).alpha = 1;
			super.getEntityById("branchTrap"+currBranchTrap+"_rope").get(Timeline).play();
		}
		
		private function configureZones():void
		{
			var entity:Entity = super.getEntityById("trap1Zone");
			var zone:Zone = entity.get(Zone);
			zone.pointHit = true;
			
			zone.entered.add(handleZoneEntered);
			
			var entity2:Entity = super.getEntityById("trap2Zone");
			var zone2:Zone = entity2.get(Zone);
			zone2.pointHit = true;
			
			zone2.entered.add(handleZoneEntered);
			
			var entity3:Entity = super.getEntityById("trap3Zone");
			var zone3:Zone = entity3.get(Zone);
			zone3.pointHit = true;
			
			zone3.entered.add(handleZoneEntered);
			
			var entity4:Entity = super.getEntityById("snap1Zone");
			var zone4:Zone = entity4.get(Zone);
			zone4.pointHit = true;
			
			zone4.entered.add(handleSnapZoneEntered);
			
			var entity5:Entity = super.getEntityById("snap2Zone");
			var zone5:Zone = entity5.get(Zone);
			zone5.pointHit = true;
			
			zone5.entered.add(handleSnapZoneEntered);
			
			var entity6:Entity = super.getEntityById("snap3Zone");
			var zone6:Zone = entity6.get(Zone);
			zone6.pointHit = true;
			
			zone6.entered.add(handleSnapZoneEntered);
			
			hitCreator = new HitCreator();
		}
		
		private function handleSnapZoneEntered(zoneId:String, characterId:String):void {
			switch(zoneId)
			{
				case "snap1Zone" :
					currBranchTrap = 1;
					super.getEntityById("branchTrap1_tree").get(Timeline).play();
					super.getEntityById("snap1Zone").remove(Zone);
					break;
				case "snap2Zone" :
					currBranchTrap = 2;
					super.getEntityById("branchTrap2_tree").get(Timeline).play();
					super.getEntityById("snap2Zone").remove(Zone);
					break;
				case "snap3Zone" :
					currBranchTrap = 3;
					super.getEntityById("branchTrap3_tree").get(Timeline).play();
					super.getEntityById("snap3Zone").remove(Zone);
					break;
			}
			super.shellApi.triggerEvent("branchSound");
		}
		
		private function handleZoneEntered(zoneId:String, characterId:String):void {
			trace("ZONE ENTERED");
			if(!noDog){
				dog.remove(NPCDetector);
			}
			
			if(zoneId == "trap2Zone"){
				if(CharUtils.getStateType(player) == CharacterState.FALL){
					return;
				}
			}
			
			if(characterId == "player"){
				SceneUtil.lockInput( this, true );
				CharUtils.lockControls(player, true);
				
				player.remove(Motion);
				player.get(Spatial).rotation = -15;
				CharUtils.setAnim(player, Tremble, false);
				
				switch(zoneId)
				{
					case "trap1Zone" :
						player.get(Spatial).x = 778;
						player.get(Spatial).y = 1745;
						super.getEntityById("netTrap1").get(Timeline).play();
						super.getEntityById("netTrap1").get(Display).moveToFront();
						
						break;
					case "trap2Zone" :
						player.get(Spatial).x = 2140;
						player.get(Spatial).y = 1191;
						super.getEntityById("netTrap2").get(Timeline).play();
						super.getEntityById("netTrap2").get(Display).moveToFront();
						
						break;
					case "trap3Zone" :
						player.get(Spatial).x = 2444;
						player.get(Spatial).y = 852;
						super.getEntityById("netTrap3").get(Timeline).play();
						super.getEntityById("netTrap3").get(Display).moveToFront();
						
						break;
				}
				player.add(new Tween());
				var playerX:Number = player.get(Spatial).x;
				player.get(Tween).to(player.get(Spatial), .23, { x:playerX+8, rotation: 0, yoyo:true, repeat:10 });
				super.shellApi.triggerEvent("ropeSound");
				AudioUtils.play(this, SoundManager.MUSIC_PATH + "caught.mp3");
				SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, trapped, true));
			}
		}
		
		private function trapped():void
		{
			SceneUtil.lockInput(this, false);
			var trappedPopup:DialogPicturePopup = new DialogPicturePopup(overlayContainer);
			trappedPopup.updateText("Van Buren caught you! You'll need to be more careful.", "Try Again");
			trappedPopup.configData("trappedPopup.swf", "scenes/survival5/shared/trappedPopup/");
			trappedPopup.popupRemoved.addOnce(trappedPopupClosed);
			addChildGroup(trappedPopup);
		}
		
		private function trappedPopupClosed():void
		{
			shellApi.loadScene(WaterEdge);
		}
		
		private function createSeeSaw():void
		{
			var i:uint;
			for( i=1;i<=3;i++){
				var clip:MovieClip = _hitContainer["log"+i];
				clip.mouseEnabled = false;
				var seesaw:Entity = getEntityById("seesaw"+i);
				var edge:Edge = new Edge();
				edge.unscaled = clip.getBounds(clip);
				seesaw.add(edge).add(new SeeSaw(20,20,-20, 20, getEntityById("log"+i)));
				Display(seesaw.get(Display)).alpha = 0;
				player.add(new Mass(30));
			}
			addSystem(new SeeSawSystem(), SystemPriorities.move);
		}
		
		private function setupBranches( clip:MovieClip ):void
		{
			var entity:Entity;
			var number:String = clip.name.substr( 6 );
			var timeline:Timeline;
			var bounceEntity:Entity = getEntityById( "bounce" + number );
			
			entity = EntityUtils.createSpatialEntity( this, clip, _hitContainer );
			entity.add( new Id( clip.name ));
			TimelineUtils.convertClip( clip, this, entity, null, false );
			
			bounceEntity.add( new TriggerHit( entity.get( Timeline )));
			
			addSystem(new TriggerHitSystem());
		}
	}
}