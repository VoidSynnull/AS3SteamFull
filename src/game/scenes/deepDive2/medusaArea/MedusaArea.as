package game.scenes.deepDive2.medusaArea
{
	import com.greensock.easing.Quad;
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.filters.GlowFilter;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialOffset;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.collider.RadialCollider;
	import game.components.entity.collider.WallCollider;
	import game.components.hit.Radial;
	import game.components.hit.Wall;
	import game.components.motion.FollowTarget;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.sound.SoundModifier;
	import game.scene.template.CharacterGroup;
	import game.scenes.deepDive1.shared.SubScene;
	import game.scenes.deepDive1.shared.components.Filmable;
	import game.scenes.deepDive1.shared.components.SubCamera;
	import game.scenes.deepDive2.DeepDive2Events;
	import game.scenes.deepDive2.medusaArea.components.Eel;
	import game.scenes.deepDive2.medusaArea.components.Hydromedusa;
	import game.scenes.deepDive2.medusaArea.components.MedusaSwitch;
	import game.scenes.deepDive2.medusaArea.systems.MedusaAreaSystem;
	import game.scenes.myth.shared.components.ElectrifyComponent;
	import game.scenes.myth.shared.systems.ElectrifySystem;
	import game.systems.SystemPriorities;
	import game.util.BitmapUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	import game.util.Utils;
	
	public class MedusaArea extends SubScene
	{
		private var _medusaAreaEvents:DeepDive2Events;
		private var savedRadial:Radial;
		public var player:Entity;
		
		private var currJelly:Number = 1;
		private var switchNum:uint;
		private var currMedusa:Entity;
		private var eel:Entity;
		
		private var glyph6:Entity;
		private var glyph2:Entity;
		
		private var puzzlePiece1:Entity;
		private var puzzlePiece2:Entity;
		
		private var tankWire:Entity;
		
		private var electrifyEffect:Entity;
		public var colorFill:GlowFilter = new GlowFilter( 0xFF0000, 1, 20, 20, 10, 1, true );
		public var colorGlow:GlowFilter = new GlowFilter( 0xFFFFFF, 1, 20, 20, 1, 1 );
		private var subCamera:SubCamera;
		
		private var flashes:Number = 0;
		private var numJellies:Number = 7;
		
		public function MedusaArea()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/deepDive2/medusaArea/";
			//showHits = true
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
			_medusaAreaEvents = DeepDive2Events(events);
			savedRadial = super.getEntityById("d6").get(Radial);
			player = shellApi.player;
			
			//toggleWall(6);
			
			setupLines();
			setupTankLine();
			setupJellies();
			setupEel();
			setupSwitches();
			setupDoors();
			setupTrap();
			setupGlyphs();
			
			electrifyEffect = new Entity;
			addSystem( new ElectrifySystem(), SystemPriorities.render );
			setupElectrifyEffect(electrifyEffect, "electrifySub");
			
			super.getEntityById("d7").remove(Wall);
			super.addSystem(new MedusaAreaSystem());
			
			//super.addLight(super.shellApi.player, 400, .4, true, false, 0x000022, 0x000022);
			super.addLight(super.shellApi.player, 400, .4, true, false, 0x000033, 0x000033);
			
			if(this.shellApi.checkEvent(_medusaAreaEvents.TRAPPED_MEDUSA)){
				var cg:CharacterGroup = new CharacterGroup();
				cg.removeCollliders(super.getEntityById("j7"));
				
				super.getEntityById("j7").get(Spatial).x = super.getEntityById("trap").get(Spatial).x;
				super.getEntityById("j7").get(Spatial).y = super.getEntityById("trap").get(Spatial).y;
				//numJellies = 6;
				
				super.getEntityById("trap").get(Timeline).gotoAndStop("end");
				super.getEntityById("d7").add(new Wall());
				
				playTankSound(); // added by bart
				turnOnTankLine(); // added by bart
			}
			
			if(!shellApi.checkEvent(_medusaAreaEvents.ENTERED_MEDUSA_AREA)){
				shellApi.completeEvent(_medusaAreaEvents.ENTERED_MEDUSA_AREA);
				//super.playMessage("circuitry");
			}
			
			subCamera = super.shellApi.player.get(SubCamera);
			subCamera.angle = 120;
			subCamera.distanceMax = 400;
			subCamera.distanceMin = 0;
			
			puzzlePiece1 = setupPuzzlePiece(super._hitContainer["puzzlePiece1"], _medusaAreaEvents.GOT_PUZZLE_PIECE_+1);
			puzzlePiece2 = setupPuzzlePiece(super._hitContainer["puzzlePiece3"], _medusaAreaEvents.GOT_PUZZLE_PIECE_+3);
			if(puzzlePiece1){
				puzzlePiece1.get(SceneInteraction).minTargetDelta.x = 80;
				puzzlePiece1.get(SceneInteraction).minTargetDelta.y = 75;	
			}
			
			super.shellApi.camera.rate = .05;
			player.add(new WallCollider())
		}
		
		// get glowing tank wire to be pulsed - added by bart
		private function setupTankLine():void
		{
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				BitmapUtils.convertContainer(_hitContainer["trap"], PerformanceUtils.defaultBitmapQuality);
			}
			tankWire = EntityUtils.createSpatialEntity(this,_hitContainer["trap"]["orange"]);
			tankWire.add(new Id("tankWire"));
			tankWire.get(Display).visible = false;
		}
		
		private function turnOnTankLine():void{
			var disp:Display = tankWire.get(Display);
			disp.visible = true;
			disp.alpha = 0;
			fadeIn(tankWire);
		}
		
		private function fadeIn(ent:Entity):void
		{
			if(ent.get(Display).visible){
				TweenUtils.globalTo(this, ent.get(Display), 0.9, {alpha:1.0 ,onComplete:fadeOut, onCompleteParams:[ent]}, "pipeGlow",0.1);
			}
		}
		
		private function fadeOut(ent:Entity):void
		{
			if(ent.get(Display).visible){
				TweenUtils.globalTo(this, ent.get(Display), 0.9, {alpha:0.7 ,onComplete:fadeIn, onCompleteParams:[ent]}, "pipeGlow",0.1);
			}
		}
		
		// add positional audio for tank when activated - added by bart
		private function playTankSound():void
		{
			var tank:Entity = getEntityById("trap");
			var audio:Audio = new Audio();
			audio.play(SoundManager.EFFECTS_PATH + "alien_gen_uw.mp3", true, [SoundModifier.POSITION]);
			tank.add(audio);
			tank.add(new AudioRange(950, 1.4, 2, Quad.easeIn));
		}
		
		public function runSwitch(sw:Entity):void {
			super.getEntityById("j"+currJelly).get(Tween).to(super.getEntityById("j"+currJelly).get(Spatial), 1, { rotation:0, ease:Sine.easeInOut });
			
			switchNum = sw.get(MedusaSwitch).idNum;
			
			currMedusa = super.getEntityById("j"+currJelly);
			medusaShock(currMedusa);
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, medusaUnShock, true));
			
			if(switchNum == 7){
				var cg:CharacterGroup = new CharacterGroup();
				cg.removeCollliders(super.getEntityById("j"+currJelly));
				
				this.shellApi.completeEvent(_medusaAreaEvents.TRAPPED_MEDUSA);
				
				// play tank sound and light up tank line - added by bart
				this.shellApi.triggerEvent("tankOn");
				playTankSound();
				turnOnTankLine();
				
				SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, runStatement2, true));
			}
			
			sw.get(Timeline).gotoAndPlay("on");
			sw.get(MedusaSwitch).open = true;
			
			toggleWall(switchNum);
			
			if(switchNum < numJellies){
				SceneUtil.addTimedEvent(this, new TimedEvent(0.5, 1, turnOnLine, true));
				currJelly++;
				if(!this.shellApi.checkEvent(_medusaAreaEvents.TRAPPED_MEDUSA) || currJelly != 7){
					super.getEntityById("j"+currJelly).get(Hydromedusa).target = player.get(Spatial);
					super.getEntityById("j"+currJelly).get(Hydromedusa).active = true;
				}
			}
		}
		
		private function turnOnLine():void {
			SceneUtil.lockInput(this, true);
			_hitContainer["line"+switchNum].visible = true;
			super.shellApi.camera.target = super.getEntityById("dclip"+switchNum).get(Spatial);
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, lineOn, true));
		}
		
		private function lineOn():void {
			super.getEntityById("dclip"+switchNum).get(Timeline).gotoAndPlay("open");
			super.shellApi.triggerEvent("doorOpen");
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, returnCamera, true));
		}
		
		private function returnCamera():void {
			super.shellApi.camera.target = player.get(Spatial);
			SceneUtil.lockInput(this, false);
			if(!shellApi.checkEvent(_medusaAreaEvents.MEDUSA_OPENED_DOOR)){
				shellApi.completeEvent(_medusaAreaEvents.MEDUSA_OPENED_DOOR);
			}
		}
		
		private function medusaShock(entity:Entity):void {
			super.shellApi.triggerEvent("attack");
			var shock:Entity = EntityUtils.getChildById(entity,"shock");
			Display(shock.get(Display)).visible = true;
			Timeline(shock.get(Timeline)).play();
		}
		
		private function medusaUnShock():void {
			var shock:Entity = EntityUtils.getChildById(currMedusa,"shock");
			Display(shock.get(Display)).visible = false;
			Timeline(shock.get(Timeline)).stop();
			currMedusa.get(Hydromedusa).stung = false;
		}
		
		public function eelShock(entity:Entity=null):void {
			frySub(entity);
			entity.get(Timeline).gotoAndPlay("shock");
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, eelUnShock, true));
		}
		
		private function eelUnShock():void {
			eel.get(Timeline).gotoAndPlay("swim");
			eel.get(Eel).stung = false;
		}
		
		public function startFrySub(entity:Entity=null):void {
			frySub(entity);
			currMedusa = super.getEntityById("j"+currJelly);
			medusaShock(currMedusa);
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, medusaUnShock, true));
		}
		
		public function frySub(entity:Entity=null):void {
			SceneUtil.lockInput(this, true);
			if(entity.get(Spatial).y <= player.get(Spatial).y){
				player.get(Motion).velocity.y = 200;
			}else{
				player.get(Motion).velocity.y = -200;
			}
			if(entity.get(Spatial).x <= player.get(Spatial).x){
				player.get(Motion).velocity.x = 200;
				player.get(Motion).rotation = 10;
			}else{
				player.get(Motion).velocity.x = -200;
				player.get(Motion).rotation = -10;
			}
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, unFrySub, true));
			var dummy:Entity = getEntityById(SubScene.PLAYER_ID);
			var dialog:Dialog = dummy.get(Dialog);
			dialog.sayById("zap");
			super.shellApi.triggerEvent("zap");
			super.shellApi.triggerEvent("attack");
			var follow:FollowTarget = new FollowTarget(Spatial(shellApi.player.get(Spatial)));
			follow.properties = new <String>["x","y","rotation"];
			SceneUtil.lockInput(this, true);
			electrifyEffect.get(Display).visible = true;
			electrifyEffect.add(follow);
			electrifyEffect.get(ElectrifyComponent).on = true;
			
			
			flashes += 6;
			subCamera.flashColor = SubCamera.RED;
			subCamera.numberOfFlashes = flashes;
		}
		
		private function unFrySub():void {
			SceneUtil.lockInput(this, false);
			//var j:Entity = super.getEntityById("j"+currJelly);
			
			electrifyEffect.get(ElectrifyComponent).on = false;
			electrifyEffect.get(Display).visible = false;
			
		}
		
		public function runStatement():void {
			//super.playMessage("keepDistance");
		}
		
		public function runStatement2():void {
			super.playMessage("astonishing");
		}
		
		private function setupGlyphs():void
		{
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				BitmapUtils.convertContainer(_hitContainer["filmGlyph1"], PerformanceUtils.defaultBitmapQuality+.1);
				BitmapUtils.convertContainer(_hitContainer["filmGlyph2"], PerformanceUtils.defaultBitmapQuality+.1);
			}
			glyph6 = EntityUtils.createSpatialEntity(this,_hitContainer["filmGlyph1"]);
			glyph2 = EntityUtils.createSpatialEntity(this,_hitContainer["filmGlyph2"]);
			
			glyph6.add(new Id("glyph_6"));
			glyph2.add(new Id("glyph_2"));
			
			var isCaptured:Boolean = shellApi.checkItemEvent(_medusaAreaEvents.GLYPH_+6);
			glyph6 = makeFilmable(glyph6,handleFilmed,200,3,true,true,isCaptured);
			
			isCaptured = shellApi.checkItemEvent(_medusaAreaEvents.GLYPH_+4);
			glyph2 = makeFilmable(glyph2,handleFilmed,200,3,true,true,isCaptured);
		}
		
		private function handleFilmed( glyph:Entity ):void
		{
			var id:String = glyph.get(Id).id;
			var filmable:Filmable = glyph.get(Filmable);
			if(id == "glyph_6"){
				handleFilmStates(glyph, filmable, _medusaAreaEvents.GLYPH_ + 6);
			}
			else if(id == "glyph_2"){
				handleFilmStates(glyph, filmable, _medusaAreaEvents.GLYPH_ + 2);
			}
		}
		
		private function handleFilmStates(glyph:Entity, filmable:Filmable, sucessEvent:String):void
		{
			var glyphId:String = glyph.get(Id).id;
			
			if(!shellApi.checkEvent(sucessEvent))
			{
				switch( filmable.state )
				{
					case filmable.FILMING_OUT_OF_RANGE:
					{
						playMessage( "filmTooFar" );
						break;
					}
					case filmable.FILMING_BLOCK:
					{
						playMessage("failedFilm");
						break;
					}
					case filmable.FILMING_START:
					{
						playMessage("startFilm");
						break;
					}
					case filmable.FILMING_STOP:
					{
						playMessage("failedFilm");
						break;
					}
					case filmable.FILMING_COMPLETE:
					{
						playMessage("sucessFilm");
						logFish( glyphId );
						break;
					}
					default:
					{
						trace( "invalid state: " + filmable.state );
						break;
					}
				}
			}
			else
			{
				playMessage("alreadyFilmed");
			}
		}
		
		private function setupTrap():void {	
			var foregroundId:String = ( PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_HIGHEST ) ? "foreground" : "foreground_mobile";
			var container:DisplayObjectContainer = super.getEntityById(foregroundId).get(Display).displayObject;
			
			var clip:MovieClip = _hitContainer["trap"];
			var trap:Entity;
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				trap = BitmapTimelineCreator.createBitmapTimeline(clip,true,true,null, PerformanceUtils.defaultBitmapQuality);
				this.addEntity(trap);
			}else{
				trap = EntityUtils.createMovingTimelineEntity(this, clip);
			}
			
			trap.add(new Id("trap"));
			
			trap.add(new MedusaSwitch(7));
		}
		
		private function setupEel():void {	
			var clip:MovieClip = _hitContainer["moray"];
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				eel = BitmapTimelineCreator.createBitmapTimeline(clip,true,true,null, PerformanceUtils.defaultBitmapQuality);
				this.addEntity(eel);
			}else{
				eel = EntityUtils.createMovingTimelineEntity(this, clip);
			}			
			eel.add(new Id("eel"));
			eel.add(new Eel(4, 1708, 3500, false));
			eel.add(new SpatialOffset());
			eel.add(new Sleep(false, true));
			eel.get(Timeline).gotoAndPlay("swim");
		}
		
		private function setupLines():void {	
			for(var i:uint=1;i<=6;i++){
				_hitContainer["line"+i].visible = false;
			}
		}
		
		private function setupDoors():void {	
			for(var i:uint=1;i<=6;i++){
				var clip:MovieClip = _hitContainer["dclip"+i];
				var door:Entity;
				if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
					door = BitmapTimelineCreator.createBitmapTimeline(clip,true,true,null, PerformanceUtils.defaultBitmapQuality);
					this.addEntity(door);
				}else{
					door = EntityUtils.createMovingTimelineEntity(this, clip);
				}
				door.add(new Id("dclip"+i));
			}
		}
		
		private function setupJellies():void {			
			for(var i:uint=1;i<=7;i++){i 
				var clip:MovieClip = _hitContainer["j"+i];
				if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH)
					convertContainer(clip, PerformanceUtils.defaultBitmapQuality);
				
				var jelly:Entity = EntityUtils.createMovingTimelineEntity(this, clip,_hitContainer, true);
				
				jelly.add(new Id("j"+i));
				jelly.add(new Tween());
				
				var randNum:Number = Utils.randInRange(-1, 1);
				MotionUtils.addWaveMotion(jelly, new WaveMotionData("y",10,0.01,"sin",randNum),this);
				
				var cg:CharacterGroup = new CharacterGroup();
				cg.addColliders(jelly);
				var spatial:Spatial = jelly.get(Spatial);
				jelly.add(new RadialCollider());
				jelly.add(new Hydromedusa(spatial.x, spatial.y));
				
				var shock:Entity;
				var shockClip:MovieClip = clip["shock"];
				shock = EntityUtils.createSpatialEntity(this, shockClip);
				TimelineUtils.convertClip(shockClip, this,shock, null, false);
				shock.add(new Id("shock"));
				Display(shock.get(Display)).visible = false;
				EntityUtils.addParentChild(shock, jelly);
				EntityUtils.turnOffSleep(shock);
				//var follow:FollowTarget = new FollowTarget(spatial,1,false,true);
				//shock.add(follow);
			}
			
			super.getEntityById("j"+currJelly).get(Hydromedusa).target = player.get(Spatial);
			super.getEntityById("j"+currJelly).get(Hydromedusa).active = true;
			super.getEntityById("j"+currJelly).get(Hydromedusa).statementWait = true;
		}
		
		private function setupSwitches():void {			
			for(var i:uint=1;i<=6;i++){
				var clip:MovieClip = _hitContainer["switch"+i];
				
				var s:Entity;
				if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
					s = BitmapTimelineCreator.createBitmapTimeline(clip,true,true,null, PerformanceUtils.defaultBitmapQuality);
					this.addEntity(s);
				}else{
					s = EntityUtils.createMovingTimelineEntity(this, clip);
				}
				s.add(new Id("switch"+i));
				s.add(new MedusaSwitch(i));
			}
		}
		
		private function setupElectrifyEffect(e:Entity, clipName:String):void {
			
			var electrify:ElectrifyComponent;
			var display:Display;
			var number:int;
			var sprite:Sprite;
			var startX:Number;
			var startY:Number;
			
			electrify = new ElectrifyComponent();
			electrify.on = false;
			
			var clip:MovieClip = _hitContainer[clipName];
			
			var foregroundId:String = ( PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_HIGHEST ) ? "foreground" : "foreground_mobile";
			var container:DisplayObjectContainer = super.getEntityById(foregroundId).get(Display).displayObject;
			container.addChild(clip);
			
			e.add(new Spatial(clip.x, clip.y));
			e.add(new Display(clip));
			
			e.add( electrify );
			
			super.addEntity(e);
			
			display = e.get( Display );
			
			for( number = 0; number < 10; number ++ )
			{
				sprite = new Sprite();
				startX = Math.random() * 60 - 60;
				startY = Math.random() * 60 - 60;				
				sprite.graphics.lineStyle( 1, 0xFFFFFF );
				sprite.graphics.moveTo( startX, startY );
				electrify.sparks.push( sprite );
				electrify.lastX.push( startX );
				electrify.lastY.push( startY );
				electrify.childNum.push( display.displayObject.numChildren );
				display.displayObject.addChildAt( sprite, display.displayObject.numChildren );
				sprite.filters = new Array( colorFill);
			}	
			e.get(Display).displayObject.filters = new Array(  colorGlow );
		}
		
		private function toggleWall(num:Number):void
		{
			var door:Entity = super.getEntityById("d"+num);
			
			if(num < 6 || num == 7){
				if(door.get(Wall)) {
					door.remove(Wall);
				}else{
					door.add(new Wall());
				}
			}else{
				if(door.get(Radial)) {
					door.remove(Radial);
				}else{
					door.add(savedRadial);
				}
			}
		}
	}
}