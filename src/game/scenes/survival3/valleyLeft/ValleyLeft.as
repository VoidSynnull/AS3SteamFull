package game.scenes.survival3.valleyLeft
{
	import com.greensock.easing.Linear;
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Camera;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import fl.transitions.Tween;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.hit.Ceiling;
	import game.components.hit.CurrentHit;
	import game.components.hit.Item;
	import game.components.hit.Platform;
	import game.components.hit.Wall;
	import game.components.hit.Zone;
	import game.components.motion.TargetSpatial;
	import game.components.motion.Threshold;
	import game.components.motion.WaveMotion;
	import game.components.timeline.Timeline;
	import game.creators.scene.SceneItemCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.Dizzy;
	import game.data.animation.entity.character.Place;
	import game.data.animation.entity.character.PointItem;
	import game.data.animation.entity.character.Stand;
	import game.data.display.BitmapWrapper;
	import game.data.sound.SoundModifier;
	import game.scene.template.ItemGroup;
	import game.scenes.poptropolis.mainStreet.components.ScreenShake;
	import game.scenes.poptropolis.mainStreet.systems.ScreenShakeSystem;
	import game.components.hit.HitTest;
	import game.systems.hit.HitTestSystem;
	import game.scenes.survival1.shared.components.TriggerHit;
	import game.scenes.survival1.shared.systems.TriggerHitSystem;
	import game.scenes.survival3.Survival3Events;
	import game.scenes.survival3.shared.Survival3Scene;
	import game.scenes.survival3.shared.components.MotionDetection;
	import game.scenes.survival3.shared.components.RadioSignal;
	import game.scenes.survival3.shared.systems.MotionDetectionSystem;
	import game.systems.SystemPriorities;
	import game.systems.hit.ItemHitSystem;
	import game.systems.hit.ResetColliderFlagSystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.ui.elements.DialogPicturePopup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	import game.util.Utils;
	
	public class ValleyLeft extends Survival3Scene
	{
		
		private var _events:Survival3Events;
		private var _enterZoneEntity:Entity;
		private var _planeZoneEntity:Entity;
		private var _topplaneZoneEntity:Entity;
		private var _ravineZoneEntity:Entity;
		private var enterZone:Zone;
		private var planeZone:Zone;
		private var topplaneZone:Zone;
		private var ravineZone:Zone;
		private var _planeBack:Entity;
		private var _planeFront:Entity;
		private var _planePiece:Entity;
		private var _radioBtn:Entity;
		private var _camerafollow:Entity;
		private var _manifest:Entity;
		private var radioRemoved:Boolean = true;
		private var branchFalling:Boolean = false;
		private var fallingThird:Boolean = false;
		private var insidePlane:Boolean = false;
		
		private var itemGroup:ItemGroup;
		
		private var cameraShake:ScreenShakeSystem;
		
		private const AIRPLANE_GROANS:String = "creaky_metal_08.mp3";
		private const AIRPLANE_CRASHES:String = "smash_0";
		
		public function ValleyLeft()
		{
			//showHits = true;
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/survival3/valleyLeft/";
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
			
			addSystem(new TriggerHitSystem());				
			addSystem(new WaveMotionSystem());
			addSystem(new MotionDetectionSystem());
			addSystem(new ResetColliderFlagSystem(), SystemPriorities.move); 
			addSystem(new ThresholdSystem());
			addSystem(new HitTestSystem());
			cameraShake = new ScreenShakeSystem();
			addSystem(cameraShake);
			
			super.shellApi.eventTriggered.add(handleEventTriggered);				
			
			bitmapArtwork();
			setupBranches();
			createEntities();			
			setupPlatformsAssets();
			setUpZones();
			
			RadioSignal(player.get(RadioSignal)).groundLevel +=2000;
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			switch(event)
			{
				case _events.USE_SAW:
					
					var currentHit:CurrentHit = player.get(CurrentHit);
					if (currentHit.hit.get(Id).id == "treePlatformBranch" || currentHit.hit.get(Id).id == "treePlatform0"){
						useKnife();
					}else{
						Dialog(player.get(Dialog)).sayById("no_use");	
					}
					break;
				case _events.RADIO:
					var wrongRadio:Dialog = player.get(Dialog);
					wrongRadio.sayById("radio_wrong");
					break;
			}
		}
		
		private function bitmapArtwork():void
		{		
			var bmpb:BitmapWrapper = this.convertToBitmap(super._hitContainer["planeback"].plane.pb);
			bmpb.bitmap.smoothing = true;
			var bmpf:BitmapWrapper = this.convertToBitmap(super._hitContainer["planefront"].plane.pf);
			bmpf.bitmap.smoothing = true;
		}
		
		private function setupBranches():void{
			var entity:Entity;
			var timeline:Timeline;
			
			for (var i:Number = 0; i <= 2; i++){
				
				var clip:MovieClip = MovieClip(super._hitContainer)["branch" + i];
				var bounceEntity:Entity = super.getEntityById( "bounce" + i );
				
				entity = EntityUtils.createSpatialEntity( this, clip );
				entity.add( new Id( clip.name ));
				TimelineUtils.convertClip( clip, this, entity, null, false );
				
				bounceEntity.add( new TriggerHit( entity.get( Timeline )));
			}
		}		
		
		private function createEntities():void
		{		
			var sceneCreator:SceneItemCreator = new SceneItemCreator();
			_manifest = EntityUtils.createSpatialEntity( this, _hitContainer["manifest_mc"], _hitContainer );
			_manifest.add( new Id( "manifest" ));
			sceneCreator.make( _manifest, new Point( 50, 100 ));
			
			if (super.shellApi.checkHasItem(_events.MANIFEST))
				super.removeEntity(_manifest);
			else
			{
				var itemHitSystem:ItemHitSystem = getSystem( ItemHitSystem ) as ItemHitSystem;
				if( !itemHitSystem )
				{
					itemHitSystem = new ItemHitSystem();
					itemHitSystem.gotItem.add(getItem);
					addSystem( itemHitSystem );
				}
			}
			
			if (!this.shellApi.checkEvent(_events.PLANE_FELL_4)){
				_planeBack = EntityUtils.createSpatialEntity( this, MovieClip( MovieClip(super._hitContainer).planeback ) );
				TimelineUtils.convertClip( MovieClip( MovieClip(super._hitContainer).planeback ), this, _planeBack, null, false );
				Timeline(_planeBack.get(Timeline)).gotoAndStop(0);
				
				_planeFront = EntityUtils.createSpatialEntity( this, MovieClip( MovieClip(super._hitContainer).planefront ) );
				TimelineUtils.convertClip( MovieClip( MovieClip(super._hitContainer).planefront ), this, _planeFront, null, false );
				Timeline(_planeFront.get(Timeline)).gotoAndStop(0);
				_planeFront.get(Timeline).handleLabel( "fell1", fallenFirst, false  );
				_planeFront.get(Timeline).handleLabel( "fell2", fallenSecond, false  );
				_planeFront.get(Timeline).handleLabel( "fall2_1", crash, true  );
				_planeFront.get(Timeline).handleLabel( "fell3", fallenThird, false  );
				_planeFront.get(Timeline).handleLabel( "fell4", fallenFourth, true  );
				
				var shake:WaveMotion = new WaveMotion();
				shake.data.push(new WaveMotionData("y", 0, .3));
				
				_planeBack.add(new Id("planeback")).add(shake).add(new SpatialAddition());
				_planeFront.add(new Id("planefront")).add(shake).add(new SpatialAddition());
				
				var spatil:Spatial = _planeFront.get(Spatial);
				planeStart = new Point(spatil.x, spatil.y);
				
			}else{
				MovieClip(super._hitContainer).planeback.visible = false;
				MovieClip(super._hitContainer).planefront.visible = false;
			}
			
			if (this.shellApi.checkEvent(_events.PLANE_PIECE_FELL)){
				_hitContainer.removeChild(_hitContainer["planePiece"]);
			}else{
				_camerafollow = EntityUtils.createSpatialEntity( this, MovieClip( MovieClip(super._hitContainer).camerafollow ) );
				
				_planePiece = EntityUtils.createMovingEntity( this, _hitContainer["planePiece"], _hitContainer );
				var clip:MovieClip = MovieClip(EntityUtils.getDisplayObject(_planePiece));
			}
			if (!this.shellApi.checkEvent(_events.PLANE_FELL_1)){
				_radioBtn = setUpRadio(_hitContainer["radio_btn"]);
			}
			else
			{
				if (this.shellApi.checkEvent(_events.PLANE_FELL_2)){
					_radioBtn = setUpRadio(_hitContainer["radio_btn2"]);
				}
			}
			
			if(shellApi.checkHasItem(_events.RADIO))
			{
				hideRadio();
			}
		}
		
		private function setUpRadio(clip:MovieClip):Entity
		{
			var radio:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			radio.add(new Id(clip.name));
			var interaction:Interaction = InteractionCreator.addToEntity(radio, ["click"], clip);
			interaction.click.add(handleRadioButtonClicked);
			return radio;
		}
		
		private function getItem(item:Entity):void
		{
			var itemGroup:ItemGroup = super.getGroupById(ItemGroup.GROUP_ID, this) as ItemGroup;
			itemGroup.showAndGetItem(item.get(Id).id);
		}
		
		private var SHAKE_VELOCITY:Number = 2;
		
		private function shakePlane(plane:Entity, motionDetected:Boolean):void
		{
			var data:WaveMotionData = WaveMotion(_planeBack.get(WaveMotion)).data[0];
			if(motionDetected)
				data.magnitude = SHAKE_VELOCITY;
			else
			{
				var tween:Tween = new Tween(data, "magnitude", Linear.easeNone, SHAKE_VELOCITY / 2, 0, .5, true);
				tween.start();
			}
		}
		
		private function handleRadioButtonClicked(entity:Entity):void	
		{
			if (insidePlane){
				lockControl();
				
				if (!this.shellApi.checkEvent(_events.PLANE_FELL_1)){
					CharUtils.moveToTarget(player, 1150, 775, true, sayClickRadio);
				}else{					
					
					CharUtils.moveToTarget(player, 1150, 1480, true, getRadio); 
				}
			}
		}
		
		private function sayClickRadio(...args):void{
			var dialog:Dialog = player.get(Dialog);
			dialog.sayById("clickradio");
			dialog.complete.add(pullRadio);
		}
		
		private function pullRadio(...args):void
		{
			Dialog(player.get(Dialog)).complete.remove(pullRadio);
			CharUtils.setDirection(player, false);
			CharUtils.setAnim(player, PointItem);
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, Command.create(shakeScreen, triggerFall)));
		}
		
		private function triggerFall():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + AIRPLANE_GROANS);
			Timeline(_planeFront.get(Timeline)).gotoAndPlay("start1"); 
			Timeline(_planeBack.get(Timeline)).gotoAndPlay("start1"); 
			SceneUtil.setCameraPoint(this, 1485, 870); 
			var cameraEntity:Entity = super.getEntityById("camera");
			var camera:Camera = cameraEntity.get(Camera);
			camera.scaleTarget = .5;
			camera.scaleRate = .1;
			
			hidePlaneInterior();
			Display(_planeBack.get(Display)).visible = true;
			
			CharUtils.setAnim(player, Dizzy);
			CharUtils.freeze(player, true);
			CharUtils.setDirection(player, true);
			player.get(Spatial).x = 1280;
			player.get(Spatial).y = 780;
			super._hitContainer.setChildIndex ( _planeFront.get(Display).displayObject, (super._hitContainer.numChildren - 1));
		}
		
		private function hideRadio():void{
			super._hitContainer["planeback"].plane.radio_mc.visible = false;
			radioRemoved = true;
		}
		
		private function getRadio(...args):void
		{
			hideRadio();
			shellApi.getItem(_events.RADIO, null, true);
			var dialog:Dialog = player.get(Dialog);
			dialog.sayById("gotradio");
			dialog.complete.add(restoreControl);			
			lockControl();
		}
		
		private function fellInRavine(zoneID:String, colliderID:String):void
		{
			if(colliderID == "player"){
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "water_splash_01.mp3");
				SceneUtil.lockInput(this);
				CharUtils.lockControls(player);
				SceneUtil.addTimedEvent( this, new TimedEvent( .5, 1, showRavinePop));				
			}
		}
		
		private function showRavinePop():void
		{
			restoreControl();
			
			var ravinePopup:DialogPicturePopup = new DialogPicturePopup(overlayContainer);
			ravinePopup.updateText("you fell down the ravine!", "try again");
			ravinePopup.configData("ravinePopup.swf", "scenes/survival3/shared/popups/");
			ravinePopup.popupRemoved.add(tryAgain);
			addChildGroup( ravinePopup);
		}
		
		private function tryAgain():void
		{
			shellApi.loadScene( ValleyLeft, 1076, 2170 );
		}
		
		private function setUpZones():void{
			
			if (!this.shellApi.checkEvent(_events.PLANE_FELL_4)){
				var doZones:Boolean = true;
				if (this.shellApi.checkEvent(_events.PLANE_FELL_3)){
					_enterZoneEntity = super.getEntityById( "enterZone3" );	
					_planeZoneEntity = super.getEntityById( "planeZone3" );	
					player.get(Spatial).x = 1625;
					player.get(Spatial).y = 2143;
					Display(_planeZoneEntity.get(Display)).isStatic = false;
				}else if (this.shellApi.checkEvent(_events.PLANE_FELL_2)){
					_enterZoneEntity = super.getEntityById( "enterZone2" );	
					_planeZoneEntity = super.getEntityById( "planeZone2" );
				}else if (this.shellApi.checkEvent(_events.PLANE_FELL_1)){
					doZones = false;
				}else{
					_enterZoneEntity = super.getEntityById( "enterZone" );	
					_planeZoneEntity = super.getEntityById( "planeZone" );
				}
				
				if (doZones == true){					
					enterZone = _enterZoneEntity.get( Zone );
					enterZone.pointHit = true;
					
					planeZone = _planeZoneEntity.get( Zone );
					planeZone.pointHit = true;
					
					if (this.shellApi.checkEvent(_events.PLANE_FELL_3)){
						showPlaneInterior();
					}else{
						hidePlaneInterior();
					}
				}
				///*
				_topplaneZoneEntity = super.getEntityById( "topplaneZone" );			
				topplaneZone = _topplaneZoneEntity.get( Zone );
				topplaneZone.pointHit = true;
				topplaneZone.inside.add(startShakeTop);
				//*/
			}			
			
			_ravineZoneEntity = super.getEntityById( "ravineZone" );			
			ravineZone = _ravineZoneEntity.get( Zone );
			ravineZone.pointHit = true;
			ravineZone.entered.add(fellInRavine);	
			_ravineZoneEntity.remove(Sleep);
			var range:AudioRange = new AudioRange(1000, 0, 1, Quad.easeIn);
			_ravineZoneEntity.add(new Audio()).add(range);
			Audio(_ravineZoneEntity.get(Audio)).play(SoundManager.EFFECTS_PATH + "river_hard_01_loop.mp3", true, SoundModifier.POSITION,5);
			
			var spatial:Spatial = getEntityById("planeZone3").get(Spatial);
			zoneStart = new Point(spatial.x, spatial.y);
		}
		
		private function setupPlatformsAssets():void
		{
			if (this.shellApi.checkEvent(_events.PLANE_FELL_4)){
				removeStartPlatforms();
				removeFall1Platforms();
				removeFall2Platforms();
				removeFall3Platforms();
				branchCutOff();
			}else if (this.shellApi.checkEvent(_events.PLANE_FELL_3)){
				removeStartPlatforms();
				removeFall1Platforms();
				removeFall2Platforms();
				addFall3Platforms();
				branchCutOff();
				Timeline(_planeFront.get(Timeline)).gotoAndStop("finishFall3");
				Timeline(_planeBack.get(Timeline)).gotoAndStop("finishFall3");
				
			}else if (this.shellApi.checkEvent(_events.PLANE_FELL_2)){
				removeStartPlatforms();
				removeFall1Platforms();
				removeFall3Platforms();
				addFall2Platforms();
				branchCutOff();
				Timeline(_planeFront.get(Timeline)).gotoAndStop("finishFall2");
				Timeline(_planeBack.get(Timeline)).gotoAndStop("finishFall2");
				
			}else if (this.shellApi.checkEvent(_events.PLANE_FELL_1)){				
				removeStartPlatforms();
				removeFall2Platforms();
				removeFall3Platforms();
				addFall1Platforms();	
				
				Timeline(_planeFront.get(Timeline)).gotoAndStop("finishFall1");
				Timeline(_planeBack.get(Timeline)).gotoAndStop("finishFall1");
				
			}else{
				removeFall1Platforms();
				removeFall2Platforms();
				removeFall3Platforms();
				
				addMotionDetection(0,4);
				
				MovieClip(super._hitContainer).branchend.visible = false;
				MovieClip(super._hitContainer).branchtip.visible = false;
			}
			
		}
		
		private function addMotionDetection(first:int, last:int):void
		{
			for(var i:int = first; i <= last; i++)
			{
				var motionDetection:MotionDetection = new MotionDetection(0,10);
				motionDetection.detected.add(shakePlane)
				getEntityById("planePlatform"+i).add(motionDetection);
			}
		}
		
		private function branchCutOff():void{
			MovieClip(super._hitContainer).branchend.visible = true;
			MovieClip(super._hitContainer).branchtip.visible = false;
			MovieClip(super._hitContainer).fullbranch.visible = false;
			
			var treePlatform:Entity = super.getEntityById("treePlatform0");
			treePlatform.remove(Platform);	
		}
		
		private function useKnife(...args):void
		{
			if(!shellApi.checkEvent(_events.PLANE_FELL_1) || shellApi.checkEvent(_events.PLANE_FELL_2))
			{
				Dialog(player.get(Dialog)).sayById("no_use");
				return;
			}
			
			lockControl();
			
			player.get(Spatial).x = 1050;
			player.get(Spatial).y = 860;
			CharUtils.setDirection(player, true);
			
			SkinUtils.setSkinPart(this.player, SkinUtils.ITEM, "armyknife");
			CharUtils.setAnim(player, Place);
			
			var timeline:Timeline = CharUtils.getTimeline(this.player);
			timeline.handleLabel("trigger", breakBranch, true);
			
		}
		
		private function breakBranch():void
		{
			CharUtils.getTimeline(this.player).gotoAndStop("trigger");
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, cutOffBranch));			
		}
		
		private function cutOffBranch():void
		{
			var cameraEntity:Entity;
			var camera:Camera;
			var cameraTarget:TargetSpatial;
			
			SkinUtils.setSkinPart(this.player, SkinUtils.ITEM, "empty");
			CharUtils.setAnim(this.player, Stand);
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + AIRPLANE_GROANS);
			
			Timeline(_planeFront.get(Timeline)).gotoAndPlay("start2"); 
			Timeline(_planeBack.get(Timeline)).gotoAndPlay("start2"); 
			SceneUtil.setCameraPoint(this, 1435, 1075); 
			cameraEntity = super.getEntityById("camera");
			camera = cameraEntity.get(Camera);
			cameraTarget = cameraEntity.get(TargetSpatial);
			camera.scaleTarget = .5;
			camera.scaleRate = .1;
			branchCutOff();
		}
		
		private function removeStartPlatforms():void{
			for (var i:Number=0;i<=4;i++){
				var planePlatform:Entity = super.getEntityById("planePlatform"+i);
				planePlatform.remove(Platform);
			}
			
			for (i=1;i<=7;i++){
				var ceiling:Entity = super.getEntityById("ceiling"+i);
				ceiling.remove(Ceiling);	
			}
			
			var wall1:Entity = super.getEntityById("wall1");
			wall1.remove(Wall);
			
			MovieClip(super._hitContainer).branchend.visible = true;
			MovieClip(super._hitContainer).branchtip.visible = true;
			MovieClip(super._hitContainer).fullbranch.visible = false;		
		}
		
		private function addFall1Platforms():void{
			for (var i:Number=5;i<=6;i++){
				var planePlatform:Entity = super.getEntityById("planePlatform"+i);
				var motionDetection:MotionDetection = new MotionDetection(0,10);
				motionDetection.detected.add(shakePlane)
				planePlatform.add(new Platform()).add(motionDetection);	
			}
		}
		
		private function removeFall1Platforms():void{
			for (var i:Number=5;i<=6;i++){
				var planePlatform:Entity = super.getEntityById("planePlatform"+i);
				planePlatform.remove(Platform);
			}
		}
		
		private function addFall2Platforms():void{			
			
			for (var i:Number=7;i<=12;i++){
				var planePlatform:Entity = super.getEntityById("planePlatform"+i);
				var motionDetection:MotionDetection = new MotionDetection(0,10);
				motionDetection.detected.add(shakePlane)
				planePlatform.add(new Platform()).add(motionDetection);	
			}
			
			for (i=8;i<=14;i++){
				var ceiling:Entity = super.getEntityById("ceiling"+i);
				ceiling.add(new Ceiling());
			}
			
			var wall2:Entity = super.getEntityById("wall2");
			wall2.add(new Wall());
			
			for (var j:Number=1;j<=2;j++){
				var treePlatform:Entity = super.getEntityById("treePlatform"+j);
				treePlatform.remove(Platform);
			}
		}
		
		private function removeFall2Platforms():void{	
			for (var i:Number=7;i<=12;i++){
				var planePlatform:Entity = super.getEntityById("planePlatform"+i);
				planePlatform.remove(Platform);
			}
			
			for (i=8;i<=14;i++){
				var ceiling:Entity = super.getEntityById("ceiling"+i);
				ceiling.remove(Ceiling);
			}
			
			var wall2:Entity = super.getEntityById("wall2");
			wall2.remove(Wall);
			
			for (var j:Number=1;j<=2;j++){
				var treePlatform:Entity = super.getEntityById("treePlatform"+j);
				treePlatform.add(new Platform());
			}
		}
		
		private function addFall3Platforms():void{			
			
			for (var i:Number=13;i<=18;i++){
				var planePlatform:Entity = super.getEntityById("planePlatform"+i);
				Display(planePlatform.get(Display)).isStatic = false;
				var motionDetection:MotionDetection = new MotionDetection(0,10);
				motionDetection.detected.add(shakePlane);
				var hitTest:HitTest = new HitTest();
				hitTest.onEnter.add(dropPlane);
				planePlatform.add(new Platform()).add(motionDetection).add(hitTest);
				planePlatform.remove(Sleep);
			}
			
			for (i=3;i<=20;i++){
				var wall:Entity = super.getEntityById("wall"+i);
				wall.add(new Wall());
				Display(wall.get(Display)).isStatic = false;
				wall.remove(Sleep);
			}
			
			for (var j:Number=5;j<=6;j++){
				var treePlatform:Entity = super.getEntityById("treePlatform"+j);
				treePlatform.remove(Platform);
			}
		}
		private var drop:Point = new Point(-10, 20);
		private var drops:uint = 0;
		private var planeStart:Point;
		private var zoneStart:Point;
		private var droppedDistance:Point = new Point();
		private function dropPlane(plat:Entity, hitId:String):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + AIRPLANE_GROANS);
			plat.remove(HitTest);
			drops++;
			var spatial:Spatial;
			for(var i:int = 13; i <= 18; i++)
			{
				spatial = getEntityById("planePlatform"+i).get(Spatial);
				spatial.x += drop.x;
				spatial.y += drop.y * drops;
			}
			for(i = 3; i <= 20; i++)
			{
				spatial = getEntityById("wall"+i).get(Spatial);
				spatial.x += drop.x;
				spatial.y += drop.y * drops;
			}
			droppedDistance.x += drop.x;
			droppedDistance.y += drop.y * drops;
			TweenUtils.entityTo(_planeFront, Spatial, .5 ,{x:planeStart.x + droppedDistance.x, y:planeStart.y + droppedDistance.y});
			TweenUtils.entityTo(_planeBack, Spatial, .5 ,{x:planeStart.x + droppedDistance.x, y:planeStart.y + droppedDistance.y});
			TweenUtils.entityTo(_planeZoneEntity, Spatial, .5 ,{x:zoneStart.x + droppedDistance.x, y:zoneStart.y + droppedDistance.y});
		}
		
		private function removeFall3Platforms():void{	
			for (var i:Number=13;i<=18;i++){
				var planePlatform:Entity = super.getEntityById("planePlatform"+i);
				planePlatform.remove(Platform);
			}
			for (i=3;i<=20;i++){
				var wall:Entity = super.getEntityById("wall"+i);
				wall.remove(Wall);
			}
			
			for (var j:Number=5;j<=6;j++){
				var treePlatform:Entity = super.getEntityById("treePlatform"+j);
				treePlatform.add(new Platform());
			}
		}
		
		private function crash():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + AIRPLANE_CRASHES+Utils.randInRange(1,3)+".mp3");
		}
		
		private function fallenFirst(...args):void
		{
			TweenUtils.entityTo(player, Spatial, 2,{x:1673, y:1400, ease:Quad.easeIn});
			SceneUtil.addTimedEvent( this, new TimedEvent( 2, 1, finishFallenFirst));
			Timeline(_planeFront.get(Timeline)).gotoAndStop("finishFall1");
			Timeline(_planeBack.get(Timeline)).gotoAndStop("finishFall1");	
			
			crash();
		}
		
		private function finishFallenFirst(...args):void{			
			CharUtils.freeze(player, false);
			CharUtils.stateDrivenOn(player, false);
			CharUtils.moveToTarget(player, 1650, 1850, true, fellOutOfPlane);
			lockControl();
			SceneUtil.setCameraTarget( this, player );
			var cameraEntity:Entity = super.getEntityById("camera");
			var camera:Camera = cameraEntity.get(Camera);
			var cameraTarget:TargetSpatial = cameraEntity.get(TargetSpatial);
			camera.scaleTarget = 1;
			camera.scaleRate = .02;
			super._hitContainer.setChildIndex ( player.get(Display).displayObject, (super._hitContainer.numChildren - 1));
			
			planeZone.exitted.removeAll();
			enterZone.entered.removeAll();
			
			addFall1Platforms();			
			removeStartPlatforms();
			
			removeEntity(_radioBtn);
			
			super.shellApi.triggerEvent(_events.PLANE_FELL_1, true);
			
		}	
		
		private function fellOutOfPlane(...args):void
		{
			var dialog:Dialog = player.get(Dialog);
			dialog.sayById("get_radio");
			dialog.complete.add(restoreControl);
		}
		
		private function fallenSecond(...args):void{
			SceneUtil.addTimedEvent( this, new TimedEvent( 1.5, 1, finishFallenSecond));
			Timeline(_planeFront.get(Timeline)).gotoAndStop("finishFall2");
			Timeline(_planeBack.get(Timeline)).gotoAndStop("finishFall2");	
			
			crash();
		}
		
		private function finishFallenSecond(...args):void{			
			CharUtils.stateDrivenOn(player, false);
			SceneUtil.setCameraTarget( this, player );
			var cameraEntity:Entity = super.getEntityById("camera");
			var camera:Camera = cameraEntity.get(Camera);
			var cameraTarget:TargetSpatial = cameraEntity.get(TargetSpatial);
			camera.scaleTarget = 1;
			camera.scaleRate = .02;
			
			removeFall1Platforms();
			addFall2Platforms();
			
			_enterZoneEntity = super.getEntityById( "enterZone2" );	
			_planeZoneEntity = super.getEntityById( "planeZone2" );			
			enterZone = _enterZoneEntity.get( Zone );
			enterZone.pointHit = true;
			
			planeZone = _planeZoneEntity.get( Zone );
			planeZone.pointHit = true;
			
			super.shellApi.triggerEvent(_events.PLANE_FELL_2, true);
			enterZone.entered.add(showPlaneInterior);
			hidePlaneInterior();
			
			_radioBtn = setUpRadio(_hitContainer["radio_btn2"]);
			
			restoreControl();		
		}
		
		private function startFallThird():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + AIRPLANE_GROANS);
			fallingThird = true;
			Timeline(_planeFront.get(Timeline)).gotoAndPlay("start3"); 
			Timeline(_planeBack.get(Timeline)).gotoAndPlay("start3"); 
			SceneUtil.setCameraPoint(this, 1495, 1725); 
			var cameraEntity:Entity = super.getEntityById("camera");
			var camera:Camera = cameraEntity.get(Camera);
			camera.scaleTarget = .5;
			camera.scaleRate = .1;
			
			hidePlaneInterior();
			Display(_planeBack.get(Display)).visible = true;
			
			CharUtils.setAnim(player, Dizzy);
			CharUtils.freeze(player, true);
			CharUtils.setDirection(player, true);
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, dropPlayer));
			
			super._hitContainer.setChildIndex ( _planeFront.get(Display).displayObject, (super._hitContainer.numChildren - 1));
		}
		
		private function dropPlayer():void
		{
			TweenUtils.entityTo(player, Spatial, 1.25, {x:1650, y:2175, ease:Quad.easeIn});
		}
		
		private function fallenThird(...args):void{
			Timeline(_planeFront.get(Timeline)).gotoAndStop("finishFall3");
			Timeline(_planeBack.get(Timeline)).gotoAndStop("finishFall3");
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, finishFallenThird));
			planeZone.exitted.removeAll();
			enterZone.entered.removeAll();
			
			crash();
		}
		
		private function finishFallenThird(...args):void{	
			CharUtils.freeze(player, false);
			CharUtils.stateDrivenOn(player, false);
			player.get(Display).visible = true;
			SceneUtil.setCameraTarget( this, player );
			var cameraEntity:Entity = super.getEntityById("camera");
			var camera:Camera = cameraEntity.get(Camera);
			var cameraTarget:TargetSpatial = cameraEntity.get(TargetSpatial);
			camera.scaleTarget = 1;
			camera.scaleRate = .02;
			super._hitContainer.setChildIndex ( player.get(Display).displayObject, (super._hitContainer.numChildren - 1));
			
			removeFall2Platforms();
			addFall3Platforms();
			
			_enterZoneEntity = super.getEntityById( "enterZone3" );	
			_planeZoneEntity = super.getEntityById( "planeZone3" );	
			Display(_planeZoneEntity.get(Display)).isStatic = false;
			enterZone = _enterZoneEntity.get( Zone );
			enterZone.pointHit = true;
			
			planeZone = _planeZoneEntity.get( Zone );
			planeZone.pointHit = true;
			
			super.shellApi.triggerEvent(_events.PLANE_FELL_3, true);
			showPlaneInterior();
			
			restoreControl();
		}
		
		private function fallenFourth(...args):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "big_splash_01.mp3");
			
			Timeline(_planeFront.get(Timeline)).gotoAndStop("finishFall4");
			Timeline(_planeBack.get(Timeline)).gotoAndStop("finishFall4");	
			CharUtils.stateDrivenOn(player, false);
			SceneUtil.setCameraTarget( this, player );
			var cameraEntity:Entity = super.getEntityById("camera");
			var camera:Camera = cameraEntity.get(Camera);
			var cameraTarget:TargetSpatial = cameraEntity.get(TargetSpatial);
			camera.scaleTarget = 1;
			camera.scaleRate = .02;
			
			removeFall3Platforms();
			
			planeZone.exitted.removeAll();
			enterZone.entered.removeAll();
			
			super.shellApi.triggerEvent(_events.PLANE_FELL_4, true);
			
			shakeScreen(restoreControl);
		}
		
		private function shakeScreen(method:Function = null):void
		{
			var target:Spatial = new Spatial();
			shellApi.camera.target = target;
			
			var shake:ScreenShake = new ScreenShake(target);
			shake.limitY = shellApi.camera.areaHeight;
			shake.shaking = true;
			shake.shakeTime = 2;
			shake.radius = 25;
			this.player.add(shake);
			
			cameraShake.playAudio.addOnce(Command.create(stopShake, method));
		}
		
		private function stopShake(start:Boolean, method:Function = null):void
		{
			if(!start)
			{
				player.remove(ScreenShake);
				SceneUtil.setCameraTarget(this, player);
				if( method != null)
					method();
			}
		}
		
		private function pieceFallen():void{
			SceneUtil.setCameraTarget(this, player);
			CharUtils.freeze(player, false);
			restoreControl();
			var cameraEntity:Entity = super.getEntityById("camera");
			var camera:Camera = cameraEntity.get(Camera);
			var cameraTarget:TargetSpatial = cameraEntity.get(TargetSpatial);
			camera.scaleTarget = 1;
			camera.scaleRate = .1;
			super.shellApi.triggerEvent(_events.PLANE_PIECE_FELL, true);
		}
		
		private function showBranchFall():void
		{
			var motion:Motion = _planePiece.get(Motion);
			motion.acceleration.y = MotionUtils.GRAVITY;
			var threshold:Threshold = new Threshold("y", ">");
			threshold.threshold = 2050;
			threshold.entered.addOnce(bounce);
			_planePiece.add(threshold);
			var cameraEntity:Entity = super.getEntityById("camera");
			var camera:Camera = cameraEntity.get(Camera);
			camera.scaleTarget = .7;
			camera.scaleRate = .1;
			
			trace("break branch");
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "branch_break_01.mp3");
			
			SceneUtil.setCameraTarget(this, _planePiece);
		}
		
		private function bounce():void
		{
			var motion:Motion = _planePiece.get(Motion);
			motion.velocity = new Point(180,  -MotionUtils.GRAVITY / 2);
			motion.rotationVelocity = 180;
			var threshold:Threshold = _planePiece.get(Threshold);
			threshold.threshold = 2500;
			threshold.entered.addOnce(pieceFallen);
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "wood_impact_01.mp3");
		}
		
		private function startShakeTop(...args):void
		{
			var currentHit:CurrentHit = player.get(CurrentHit);
			
			if( currentHit != null )
			{				
				if( currentHit.hit != null )
				{
					for (var i:Number=0;i<=3;i++)
					{
						if (currentHit.hit.get(Id).id == "planePlatform"+i)
						{
							if (!this.shellApi.checkEvent(_events.PLANE_PIECE_FELL) && !branchFalling)
							{
								branchFalling = true;
								lockControl();
								Sleep(currentHit.hit.get(Sleep)).ignoreOffscreenSleep = true;
								SceneUtil.lockInput(this);
								SceneUtil.addTimedEvent( this, new TimedEvent( .2, 1, showBranchFall));	
							}
							break;
						}
					}
				}
			}
		}
		
		private function showPlaneInterior(...args):void
		{
			insidePlane = true;
			if(_radioBtn != null)
			{
				ToolTipCreator.addToEntity(_radioBtn);
			}
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "shaky_vessel_01_loop.mp3",2,true);
			enterZone.entered.removeAll()
			planeZone.exitted.add(hidePlaneInterior);
			Display(_planeFront.get(Display)).visible = false;
			
			var i:Number;
			var planePlatform:Entity;
			var ceiling:Entity;
			var item:Item
			
			if (this.shellApi.checkEvent(_events.PLANE_FELL_3)){
				for (i=13;i<=18;i++){
					planePlatform = super.getEntityById("planePlatform"+i);
					planePlatform.add(new Platform());	
				}
				
				for (i=3;i<=20;i++){
					var wall:Entity = super.getEntityById("wall"+i);
					wall.add(new Wall());
				}
				
			}else if (this.shellApi.checkEvent(_events.PLANE_FELL_2)){
				for (i=10;i<=12;i++){
					planePlatform = super.getEntityById("planePlatform"+i);
					planePlatform.add(new Platform());	
				}
				
				for (i=8;i<=14;i++){
					ceiling = super.getEntityById("ceiling"+i);
					ceiling.add(new Ceiling());
				}
				
				var treePlatform:Entity = super.getEntityById("treePlatform3");
				treePlatform.remove(Platform);
				if (!radioRemoved) Interaction(_radioBtn.get(Interaction)).lock = false;
				if (!shellApi.checkHasItem(_events.MANIFEST)) 
				{
					item = new Item();
					item.minRangeX = 50;
					item.minRangeY = 150;
					_manifest.add(item);
				}
			}else{
				for (i=3;i<=4;i++){
					planePlatform = super.getEntityById("planePlatform"+i);
					planePlatform.add(new Platform());	
				}
				
				for (i=1;i<=7;i++){
					ceiling = super.getEntityById("ceiling"+i);
					ceiling.add(new Ceiling());
				}
				
				var wall1:Entity = super.getEntityById("wall1");
				wall1.add(new Wall());
				if (!radioRemoved) Interaction(_radioBtn.get(Interaction)).lock = false;
				if (!shellApi.checkHasItem(_events.MANIFEST))
				{
					item = new Item();
					item.minRangeX = 50;
					item.minRangeY = 150;
					_manifest.add(item);
				}
			}
		}
		
		private function hidePlaneInterior(...args):void
		{
			insidePlane = false;
			if(_radioBtn != null)
			{
				ToolTipCreator.removeFromEntity(_radioBtn);
			}
			AudioUtils.stop(this, SoundManager.EFFECTS_PATH + "shaky_vessel_01_loop.mp3");
			planeZone.exitted.removeAll()
			enterZone.entered.add(showPlaneInterior);
			Display(_planeFront.get(Display)).visible = true;
			
			var i:Number;
			var planePlatform:Entity;
			var ceiling:Entity;
			
			var cameraEntity:Entity;
			var camera:Camera;
			var cameraTarget:TargetSpatial;
			
			if (this.shellApi.checkEvent(_events.PLANE_FELL_3))
			{
				lockControl();
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + AIRPLANE_GROANS);
				Timeline(_planeFront.get(Timeline)).gotoAndPlay("start4"); 
				Timeline(_planeBack.get(Timeline)).gotoAndPlay("start4"); 
				SceneUtil.setCameraPoint(this, 1495, 1825); 
				cameraEntity = super.getEntityById("camera");
				camera = cameraEntity.get(Camera);
				cameraTarget = cameraEntity.get(TargetSpatial);
				camera.scaleTarget = .5;
				camera.scaleRate = .1;
				SceneUtil.addTimedEvent( this, new TimedEvent( 3, 1, fallenFourth));	
				
				removeFall3Platforms();
				
			}else if (this.shellApi.checkEvent(_events.PLANE_FELL_2)){
				
				if(shellApi.checkHasItem(_events.RADIO) && !fallingThird)
				{
					startFallThird();
					return;
				}
				
				for (i=10;i<=12;i++){
					planePlatform = super.getEntityById("planePlatform"+i);
					planePlatform.remove(Platform);	
				}
				
				for (i=8;i<=14;i++){
					ceiling = super.getEntityById("ceiling"+i);
					ceiling.remove(Ceiling);
				}
				
				var treePlatform:Entity = super.getEntityById("treePlatform3");
				treePlatform.add(new Platform());	
				if (!radioRemoved) Interaction(_radioBtn.get(Interaction)).lock = true;
				if (!shellApi.checkHasItem(_events.MANIFEST)) _manifest.remove(Item);
			}else{
				for (i=3;i<=4;i++){
					planePlatform = super.getEntityById("planePlatform"+i);
					planePlatform.remove(Platform);	
				}
				for (i=1;i<=7;i++){
					ceiling = super.getEntityById("ceiling"+i);
					ceiling.remove(Ceiling);
				}
				var wall1:Entity = super.getEntityById("wall1");
				wall1.remove(Wall);
				if (!radioRemoved) Interaction(_radioBtn.get(Interaction)).lock = true;
				if (!shellApi.checkHasItem(_events.MANIFEST))_manifest.remove(Item);
			}			
			
		}
		
		
		private function lockControl(...args):void
		{
			MotionUtils.zeroMotion(player);
			Spatial(player.get(Spatial)).rotation = 0;
			CharUtils.lockControls(super.player, true, true);
			SceneUtil.lockInput(this, true);
		}
		
		private function restoreControl(...args):void
		{
			CharUtils.lockControls(super.player, false, false);
			MotionUtils.zeroMotion(super.player);
			SceneUtil.lockInput(this, false);
		}
	}
}