package game.scenes.ghd.ghostShip
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Children;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.Character;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.hit.Door;
	import game.components.hit.Zone;
	import game.components.motion.Edge;
	import game.components.render.Light;
	import game.components.render.LightOverlay;
	import game.components.render.LightRange;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.PointItem;
	import game.data.animation.entity.character.Tremble;
	import game.scenes.ghd.GalacticHotDogScene;
	import game.systems.render.LightRangeSystem;
	import game.systems.render.LightSystem;
	import game.systems.scene.DoorSystem;
	import game.systems.timeline.TimelineVariableSystem;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	
	public class GhostShip extends GalacticHotDogScene
	{		
		private var _piece1:Entity;
		private var _piece2:Entity;
		private var _piece3:Entity;
		private var _hand:Entity;
		private var _captain:Entity;
		private var _exitDoor:Entity;
		private var _head:Entity;
		
		private var BOX_OPEN:String = SoundManager.EFFECTS_PATH + "door_hydrolics_open_01.mp3"; 
		private var BARREL_OPEN:String = SoundManager.EFFECTS_PATH + "squish_05.mp3"; 
		private var HAND_OPEN:String = SoundManager.EFFECTS_PATH + "openDoor_creakyGrill.mp3"; 
		private var GROWL:String = SoundManager.EFFECTS_PATH + "bear_growl_02.mp3";
		private var GATE_SOUND:String  = SoundManager.EFFECTS_PATH + "door_hatch_01.mp3";
		private var LEVER_SOUND:String  = SoundManager.EFFECTS_PATH + "machineLever.mp3";
		private var HAND_SHAKE:String  = SoundManager.EFFECTS_PATH + "shake_machine_01.mp3";

		public function GhostShip()
		{
			super();
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{			
			super.groupPrefix = "scenes/ghd/ghostShip/";
			//showHits = true;
			super.init(container);
			
			super.id = "GhostShip";
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}	
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			//trace(event)
		}
		
		private function backToShip(...p):void
		{
			DoorSystem(getSystem(DoorSystem)).openDoor(_exitDoor);
		}
		
		override protected function addCharacterDialog(container:Sprite):void
		{
			setupCaptain();
			
			super.addCharacterDialog(container);
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			addSystem( new TimelineVariableSystem() );
			
			PerformanceUtils.determineAndSetDefaultBitmapQuality();
			
			shellApi.eventTriggered.add(handleEventTriggered);
			
			setupPieces();
			
			setupBoxes();
			
			setupBarrels();
			
			setupHand();
			
			setupDoors();
			
			setupOverlay();
			
			// exit door
			_exitDoor = getEntityById("door1");
			_exitDoor.add(new Sleep(false, true));
			var door:Door = _exitDoor.get(Door);
			door.opened = true;
			var inter:SceneInteraction = _exitDoor.get(SceneInteraction);
			inter.reached.add(handleDoor);
		}
		
		private function setupOverlay():void
		{
			addLight(super.shellApi.player, 400, .70, true, false, 0x00000, 0x000033);
		}
		
		private function handleDoor(p:Entity, doorEnt:Entity):void
		{
			if(shellApi.checkEvent(_events.GOT_ALL_MAP_PIECES)){
				backToShip();
			}
			else{
				Dialog(player.get(Dialog)).sayById("needPieces");
			}
		}
		
		private function setupPieces():void
		{
			// make clickable pieces
			// barrel piece, use timeline
			if( !shellApi.checkEvent( _events.GOT_MAP_1 ))
			{
				var clip:MovieClip = _hitContainer["piece1"];
				_piece1 = EntityUtils.createMovingTimelineEntity(this, clip, _hitContainer, false);
				if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
					BitmapTimelineCreator.convertToBitmapTimeline(_piece1, null, true, null, PerformanceUtils.defaultBitmapQuality);
				}
				_piece1.add(new Id("piece1"));
			}
			else
			{
				_hitContainer.removeChild( _hitContainer[ "piece1" ]);
			}
			// box piece
			if( !shellApi.checkEvent( _events.GOT_MAP_2 ))
			{
				clip = _hitContainer["piece2"];
				if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
					BitmapUtils.convertContainer(clip, PerformanceUtils.defaultBitmapQuality);
				}
				_piece2 = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
				_piece2.add(new Id("piece2"));
			}
			else
			{
				_hitContainer.removeChild( _hitContainer[ "piece2" ]);
			}
			// captain's piece
			if( !shellApi.checkEvent( _events.GOT_MAP_3 ))
			{
				clip = _hitContainer["piece3"];
				if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
					BitmapUtils.convertContainer(clip, PerformanceUtils.defaultBitmapQuality);
				}
				_piece3 = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
				_piece3.add(new Id("piece3"));
			
				// starts out interact-able, others get this later
				InteractionCreator.addToEntity( _piece3, [ InteractionCreator.CLICK ]);
				var sceneInteraction:SceneInteraction = new SceneInteraction();
				sceneInteraction.reached.addOnce(getPiece);
				_piece3.add( sceneInteraction );	
				ToolTipCreator.addToEntity(_piece3);
			}
			else
			{
				_hitContainer.removeChild( _hitContainer[ "piece3" ]);
			}			
		}
		
		private function setupBoxes():void
		{
			// clicks
			var box:Entity;
			var clip:MovieClip;	
			var boxSequence:BitmapSequence;
			for (var i:int = 0; i < 3; i++) 
			{
				clip = _hitContainer["box"+i];
				box = EntityUtils.createMovingTimelineEntity(this, clip, _hitContainer);
				box.add(new Id("box"+i));
				if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
					if(!boxSequence){
						boxSequence = BitmapTimelineCreator.createSequence(clip, true, PerformanceUtils.defaultBitmapQuality);
					}
					BitmapTimelineCreator.convertToBitmapTimeline(box, clip, true, boxSequence, PerformanceUtils.defaultBitmapQuality);
				}
				InteractionCreator.addToEntity( box, [ InteractionCreator.CLICK ]);
				var sceneInteraction:SceneInteraction = new SceneInteraction();
				
				box.add( sceneInteraction );	
				ToolTipCreator.addToEntity(box);
				if(i == 1){
					// i am the box ghost!
					var zone:Zone = getEntityById("boxZone").get(Zone);
					zone.entered.addOnce(Command.create(openBoxGhost,box));
				}else{
					sceneInteraction.reached.addOnce(openBox);
				}
			}
			clip = _hitContainer["head"];
			_head = EntityUtils.createMovingTimelineEntity(this, clip, _hitContainer);
			_head.add(new Id("head"));
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				BitmapTimelineCreator.convertToBitmapTimeline(_head, clip, true, null, PerformanceUtils.defaultBitmapQuality);
			}
		}
		
		private function openBoxGhost(z:String, p:String, box:Entity):void
		{
			openBox(null,box);	
		}
		
		private function openBox(j:*, box:Entity):void
		{
			var tl:Timeline = box.get(Timeline);
			tl.gotoAndPlay("opening");
			tl.handleLabel("end",Command.create(showPiece,box));
			// SOUND
			AudioUtils.play(this, BOX_OPEN, 1, false);
		}
		
		private function showPiece(box:Entity):void
		{
			var sceneInteraction:SceneInteraction;
			var bId:String = Id(box.get(Id)).id;
			if(bId == "box1"){
				// rawr - show monster
				scarePlayer(true);
				Timeline(_head.get(Timeline)).gotoAndPlay("roar");
				AudioUtils.play(this, GROWL, 1.0);
			}
			else if(bId == "box2"){
				if(_piece2){
					InteractionCreator.addToEntity( _piece2, [ InteractionCreator.CLICK ]);
					sceneInteraction = new SceneInteraction();
					sceneInteraction.reached.addOnce(getPiece);
					_piece2.add( sceneInteraction );	
					ToolTipCreator.addToEntity(_piece2);
				}
			}
			else if(bId == "barrel1"){
				if(_piece1){
					InteractionCreator.addToEntity( _piece1, [ InteractionCreator.CLICK ]);
					sceneInteraction = new SceneInteraction();
					sceneInteraction.reached.addOnce(getPiece);
					_piece1.add( sceneInteraction );
					ToolTipCreator.addToEntity(_piece1);
				}
			}
		}
		
		private function getPiece(player:Entity, piece:Entity):void
		{	
			var firstPiece:Boolean = !shellApi.checkHasItem(_events.MAP_O_SPHERE);
			
			if(firstPiece){
				shellApi.getItem( _events.MAP_O_SPHERE,null, true);
				Dialog(player.get(Dialog)).sayById("gotPiece");
			}else{
				shellApi.showItem(_events.MAP_O_SPHERE,null);
			}
			switch(piece.get(Id).id)
			{
				case "piece1":
				{
					shellApi.triggerEvent(_events.GOT_MAP_1,true);
					SceneUtil.addTimedEvent(this, new TimedEvent(1,1, checkFinish));
					break;
				}
				case "piece2":
				{
					shellApi.triggerEvent(_events.GOT_MAP_2,true);
					SceneUtil.addTimedEvent(this, new TimedEvent(1,1, checkFinish));
					break;
				}				
				case "piece3":
				{
					shellApi.triggerEvent(_events.GOT_MAP_3,true);
					if(firstPiece){
						SceneUtil.lockInput(this, true);
						Dialog(player.get(Dialog)).complete.addOnce(captainSpeaks);
					}else{
						SceneUtil.addTimedEvent(this, new TimedEvent(1.1,1, captainSpeaks));
					}
					break;
				}
			}
			removeEntity(piece);
		}
		
		private function checkFinish(...p):void
		{
			if(shellApi.checkEvent(_events.GOT_ALL_MAP_PIECES)){
				Dialog(player.get(Dialog)).sayById("leave");
			}
		}
		
		private function setupBarrels():void
		{
			var barrel:Entity;
			var clip:MovieClip;
			var sequence:BitmapSequence;
			for (var i:int = 0; i < 5; i++) 
			{
				clip = _hitContainer["barrel"+i];
				barrel = EntityUtils.createMovingTimelineEntity(this, clip, _hitContainer);
				barrel.add(new Id("barrel"+i));
				if(i==1){
					if(_piece1){
						DisplayUtils.moveToTop(EntityUtils.getDisplayObject(_piece1));
					}
					DisplayUtils.moveToTop(EntityUtils.getDisplayObject(barrel));
					DisplayUtils.moveToTop(EntityUtils.getDisplayObject(player));
				}
				if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
					BitmapTimelineCreator.convertToBitmapTimeline(barrel, clip, true, null, PerformanceUtils.defaultBitmapQuality);
				}
				InteractionCreator.addToEntity( barrel, [ InteractionCreator.CLICK ]);
				var sceneInteraction:SceneInteraction = new SceneInteraction();				
				sceneInteraction.reached.addOnce(openBarrel);
				barrel.add( sceneInteraction );	
				ToolTipCreator.addToEntity(barrel);
			}
			
			// lights
			var light:Entity;
			for (var j:int = 0; j < 5; j++) 
			{
				clip = _hitContainer["bButton"+j];
				light = EntityUtils.createMovingTimelineEntity(this, clip, _hitContainer, true, 20);
				if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
					BitmapTimelineCreator.convertToBitmapTimeline(light, clip, true, null, PerformanceUtils.defaultBitmapQuality);
				}
			}
		}
		
		private function openBarrel(j:*, barrel:Entity):void
		{
			var tl:Timeline = barrel.get(Timeline);
			tl.gotoAndPlay("appear");
			tl.handleLabel("end",Command.create(showPiece,barrel));
			if(barrel.get(Id).id == "barrel1"){
				if(_piece1){
					Timeline(_piece1.get(Timeline)).gotoAndPlay("appear");
				}
			}else if(barrel.get(Id).id == "barrel0"){
				tl.handleLabel("end",growl);
			}
			// SOUND
			AudioUtils.play(this, BARREL_OPEN, 1, false);
		}
		
		private function growl(...p):void
		{
			scarePlayer();
			AudioUtils.play(this, GROWL, 1, false);			
		}
		
		private function setupHand():void
		{	
			var sequence:BitmapSequence;
			var clip:MovieClip = _hitContainer["hand"];
			_hand = EntityUtils.createMovingTimelineEntity(this, clip, _hitContainer);
			_hand.add(new Id("hand"));
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				BitmapTimelineCreator.convertToBitmapTimeline(_hand, clip, true, null, PerformanceUtils.defaultBitmapQuality);
			}
			
			var handZone:Zone = getEntityById("handZone").get(Zone);
			handZone.entered.addOnce(shakeHand);
		}
		
		private function shakeHand(...p):void
		{
			var tl:Timeline = _hand.get(Timeline);
			
			tl.gotoAndPlay("shake");
			// SOUND
			AudioUtils.play(this, HAND_SHAKE, 1, false);
		}
		
		private function openHand(...p):void
		{
			SceneUtil.setCameraTarget(this, _hand);
			var tl:Timeline = _hand.get(Timeline);
			tl.gotoAndPlay("appear");
			scarePlayer(true,false);
			// SOUND
			AudioUtils.play(this, HAND_OPEN, 1, false);
		}
		
		private function scarePlayer(lock:Boolean = true, jumpBack:Boolean = true):void
		{
			CharUtils.setAnim(player,Grief);
			CharacterMotionControl(player.get(CharacterMotionControl)).spinEnd = true;
			var plTl:Timeline = Timeline(player.get(Timeline));
			if(lock){
				SceneUtil.lockInput(this, true);
				plTl.handleLabel("end",unlock);
			}
			MotionUtils.zeroMotion(player,"x");
			
			if(jumpBack){
				plTl.handleLabel("end",run);
			}
		}
		
		private function run(...p):void
		{
			var targ:Point = EntityUtils.getPosition(player);
			targ.x -= 300;
			CharUtils.moveToTarget(player,targ.x,targ.y);
		}
		
		private function unlock(...p):void
		{
			SceneUtil.lockInput(this, false, false);
			SceneUtil.setCameraTarget(this, player);
		}
		
		private function setupCaptain():void
		{
			var clip:MovieClip = _hitContainer[ "captain" ];
			_captain = EntityUtils.createMovingTimelineEntity( this, clip, null, false, 28 );
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				BitmapTimelineCreator.convertToBitmapTimeline(_captain, clip, true, null, PerformanceUtils.defaultBitmapQuality,28);
			}
			var dialog:Dialog = new Dialog();
			dialog.faceSpeaker = false;
			dialog.dialogPositionPercents = new Point( 1.2, 1 );
			// mouth control
			dialog.start.add(Command.create(runTalk,_captain));
			dialog.complete.add(Command.create(runIdle,_captain));
			runIdle(null,_captain);
			
			_captain.add( dialog );
			_captain.add( new Id( "captain" ));
			
			_captain.add( new Edge( 50, 50, 50, 50 ));
			var character:Character = new Character();
			character.costumizable = false;
			_captain.add(character);
		}
		
		private function runIdle(junk:*, char:Entity):void
		{
			var timeline:Timeline = char.get(Timeline);
			timeline.gotoAndPlay("slumping");
		}
		
		private function runTalk(junk:*, char:Entity):void
		{
			var timeline:Timeline = char.get(Timeline);
			timeline.gotoAndPlay("waking");
		}
		
		private function captainSpeaks(...p):void
		{
			SceneUtil.setCameraTarget(this, _captain);
			scarePlayer(true, false);
			Timeline(player.get(Timeline)).handleLabel("end",doFear);
			
			Dialog(_captain.get(Dialog)).sayById("rage");
			Dialog(_captain.get(Dialog)).complete.addOnce(captainDead);
			Dialog(player.get(Dialog)).complete.addOnce(checkFinish);
			//SOUND
			AudioUtils.play(this, GROWL, 1, false);
		}
		
		private function doFear(...p):void
		{
			CharUtils.setAnim(player,Tremble,false,300);
		}
		
		private function captainDead(...p):void
		{
			// conclude and warp back to ship if got all pieces
			SceneUtil.setCameraTarget(this, player);
			SceneUtil.lockInput(this, false);
			// end anim
			Timeline(player.get(Timeline)).gotoAndPlay("stopSweat");
		}
		
		private function setupDoors():void
		{
			var gateClip:MovieClip;
			var leverClip:MovieClip;
			var gate:Entity;
			var lever:Entity;
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				var leverSeq:BitmapSequence = BitmapTimelineCreator.createSequence(_hitContainer["lever"+0],true, PerformanceUtils.defaultBitmapQuality);
				var gateSeq:BitmapSequence = BitmapTimelineCreator.createSequence(_hitContainer["gate"+0],true, PerformanceUtils.defaultBitmapQuality);
			}
			for (var i:int = 0; i < 3; i++) 
			{
				gateClip = _hitContainer["gate"+i];
				gate = EntityUtils.createMovingTimelineEntity(this, gateClip, _hitContainer, false);
				gate.add(new Sleep(false, true));
				gate.add(new Id("gate"+i));
				
				leverClip = _hitContainer["lever"+i];
				lever = EntityUtils.createMovingTimelineEntity(this, leverClip, _hitContainer, false);
				lever.add(new Id("lever"+i));
				
				if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
					BitmapTimelineCreator.convertToBitmapTimeline(gate, null, true, gateSeq, PerformanceUtils.defaultBitmapQuality);
					BitmapTimelineCreator.convertToBitmapTimeline(lever, null, true, leverSeq, PerformanceUtils.defaultBitmapQuality);
				}
				
				InteractionCreator.addToEntity( lever, [ InteractionCreator.CLICK ]);
				var sceneInteraction:SceneInteraction = new SceneInteraction();	
				sceneInteraction.minTargetDelta = new Point(50,60);
				sceneInteraction.reached.addOnce(Command.create(openGate,gate));
				if(i==1){
					// enable hand trigger
					sceneInteraction.reached.add(enableHand);
				}
				lever.add( sceneInteraction );
				ToolTipCreator.addToEntity(lever);
				lever.add(new Children(getEntityById("gate"+i+"B")));
			}
		}
		
		private function enableHand(...p):void
		{
			var handZone:Zone = getEntityById("handZone").get(Zone);
			handZone.entered.addOnce(openHand);
		}
		
		private function openGate(p:Entity, lever:Entity, gate:Entity):void
		{
			CharUtils.setAnim(player, PointItem);
			var playerTL:Timeline = player.get(Timeline);
			var gateTl:Timeline = gate.get(Timeline);
			var leverTl:Timeline = lever.get(Timeline);
			
			playerTL.handleLabel("pointing",Command.create(leverTl.gotoAndPlay,"down"));
			playerTL.handleLabel("end",Command.create(seeGate,gate));
			playerTL.handleLabel("end",Command.create(gateTl.gotoAndPlay,"closed"));
			
			var sceneInteraction:SceneInteraction = lever.get(SceneInteraction);				
			sceneInteraction.reached.addOnce(Command.create(closeGate,gate));
			Children(lever.get(Children)).children[0].add(new Sleep(true, true));
			AudioUtils.playSoundFromEntity(lever, LEVER_SOUND, 700, 0.25, 1.25, Quad.easeInOut);	
		}		
		
		private function seeGate(gate:Entity):void
		{
			SceneUtil.setCameraTarget(this,gate);
			// SOUND
			AudioUtils.playSoundFromEntity(gate, GATE_SOUND, 700, 0.25, 1.25, Quad.easeInOut);
			SceneUtil.addTimedEvent(this, new TimedEvent(1.5,1,Command.create(SceneUtil.setCameraTarget,this,player)));
		}
		
		private function closeGate(p:Entity, lever:Entity, gate:Entity):void
		{
			CharUtils.setAnim(player, PointItem);
			var playerTL:Timeline = player.get(Timeline);
			var gateTl:Timeline = gate.get(Timeline);
			var leverTl:Timeline = lever.get(Timeline);
			
			playerTL.handleLabel("pointing",Command.create(leverTl.gotoAndPlay,"up"));
			playerTL.handleLabel("end",Command.create(seeGate,gate));
			playerTL.handleLabel("end",Command.create(gateTl.gotoAndStop,"closed"));
			var sceneInteraction:SceneInteraction = lever.get(SceneInteraction);				
			sceneInteraction.reached.addOnce(Command.create(openGate,gate));
			Children(lever.get(Children)).children[0].add(new Sleep(false, true));
			AudioUtils.playSoundFromEntity(lever, LEVER_SOUND, 700, 0.25, 1.25, Quad.easeInOut);
		}	
		
		public function addLight(entity:Entity, radius:Number = 200, darkAlpha:Number = .9, gradient:Boolean = true, useRange:Boolean = false, color:uint = 0x000099, shipColor:uint = 0x000000, lightAlpha:Number = 0, horizontalRange:Boolean = false, minRange:Number = NaN, maxRange:Number = NaN):Entity
		{
			var lightOverlayEntity:Entity = super.getEntityById("lightOverlay");
			
			if(lightOverlayEntity == null)
			{
				super.addSystem(new LightSystem());
				
				var lightOverlay:Sprite = new Sprite();
				super.overlayContainer.addChildAt(lightOverlay, 0);
				lightOverlay.mouseEnabled = false;
				lightOverlay.mouseChildren = false;
				lightOverlay.graphics.clear();
				lightOverlay.graphics.beginFill(color, darkAlpha);
				lightOverlay.graphics.drawRect(0, 0, super.shellApi.viewportWidth, super.shellApi.viewportHeight);
				
				var display:Display = new Display(lightOverlay);
				display.isStatic = true;
				
				lightOverlayEntity = new Entity();
				lightOverlayEntity.add(new Spatial());
				lightOverlayEntity.add(display);
				lightOverlayEntity.add(new Id("lightOverlay"));
				lightOverlayEntity.add(new LightOverlay(darkAlpha, color));
				
				super.addEntity(lightOverlayEntity);
				
				if(useRange)
				{
					super.addSystem(new LightRangeSystem());
					
					if(isNaN(minRange))
					{
						minRange = 0;
					}
					
					if(isNaN(maxRange))
					{
						if(horizontalRange)
						{
							maxRange = super.sceneData.cameraLimits.right;
						}
						else
						{
							maxRange = super.sceneData.cameraLimits.bottom;
						}
					}
					
					entity.add(new LightRange(minRange, maxRange, radius, darkAlpha, lightAlpha, horizontalRange));
				}
			}
			
			if(useRange)
			{
				darkAlpha *= 2;
				radius *= 2;
				lightAlpha *= 2;
			}
			
			entity.add(new Light(radius, darkAlpha, lightAlpha, gradient, shipColor, color));
			
			return lightOverlayEntity;
		}
		
		
		
		
		
	}
}