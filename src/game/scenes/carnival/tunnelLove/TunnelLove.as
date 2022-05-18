package game.scenes.carnival.tunnelLove{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.systems.MotionSystem;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.part.SkinPart;
	import game.components.entity.collider.PlatformCollider;
	import game.components.hit.Door;
	import game.components.hit.Zone;
	import game.components.timeline.Timeline;
	import game.creators.scene.HitCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.KissStart;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Tremble;
	import game.scenes.carnival.CarnivalEvents;
	import game.data.scene.characterDialog.DialogData;
	import game.data.scene.hit.HitType;
	import game.data.scene.hit.MovingHitData;
	import game.data.sound.SoundModifier;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.carnival.ridesEvening.RidesEvening;
	import game.scenes.carnival.ridesNight.RidesNight;
	import game.scenes.carnival.tunnelLove.components.Boat;
	import game.scenes.carnival.tunnelLove.systems.BoatSystem;
	import game.systems.SystemPriorities;
	import game.systems.timeline.TimelineClipSystem;
	import game.systems.timeline.TimelineControlSystem;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	public class TunnelLove extends PlatformerGameScene
	{
		public function TunnelLove()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carnival/tunnelLove/";
			
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
			
			super.shellApi.eventTriggered.add(handleEventTriggered);
			
			_events = new CarnivalEvents();
			
			initEntities();
			initSounds();
			initSystems();
			initZones();
			setDoors();
			setDepths();
			
			// set player on boat in entrance
			Spatial(super.player.get(Spatial)).x = 150;
			Spatial(super.player.get(Spatial)).y = 745;
			
			// check events
			if(!super.shellApi.checkEvent(_events.TEENS_IN_TUNNEL) || super.shellApi.checkEvent(_events.TEENS_FRIGHTENED)){
				super.removeEntity(_loverBoy);
				super.removeEntity(_loverGirl);
				super.removeEntity(_boat2);
			}
		}
		
		private function initEntities():void{
			
			_beads1 = TimelineUtils.convertClip(super._hitContainer["beads1"], this);
			_beads1.add(new Display(super._hitContainer["beads1"]));
			_beads1.add(new Spatial());
			
			_beads2 = TimelineUtils.convertClip(super._hitContainer["beads2"], this);
			_beads2.add(new Display(super._hitContainer["beads2"]));
			_beads2.add(new Spatial());
			
			_beads3 = TimelineUtils.convertClip(super._hitContainer["beads3"], this);
			_beads3.add(new Display(super._hitContainer["beads3"]));
			_beads3.add(new Spatial());
			
			_beads4 = TimelineUtils.convertClip(super._hitContainer["beads4"], this);
			_beads4.add(new Display(super._hitContainer["beads4"]));
			_beads4.add(new Spatial());
			
			_couple1 = TimelineUtils.convertClip(super._hitContainer["couple1"], this);
			_couple1.add(new Display(super._hitContainer["couple1"]));
			_couple1.add(new Spatial());
			
			_couple2 = TimelineUtils.convertClip(super._hitContainer["couple2"], this);
			_couple2.add(new Display(super._hitContainer["couple2"]));
			_couple2.add(new Spatial());
			
			_couple3 = TimelineUtils.convertClip(super._hitContainer["couple3"], this);
			_couple3.add(new Display(super._hitContainer["couple3"]));
			_couple3.add(new Spatial());
			
			_couple4 = TimelineUtils.convertClip(super._hitContainer["couple4"], this);
			_couple4.add(new Display(super._hitContainer["couple4"]));
			_couple4.add(new Spatial());
			
			var movingHitData:MovingHitData = new MovingHitData();
			movingHitData.visible = "boatHit";
			
			var hitCreator:HitCreator = new HitCreator();
			_boatHit = hitCreator.createHit(super._hitContainer["boatHit"], HitType.MOVING_PLATFORM, movingHitData, this);
			
			var motion:Motion = _boatHit.get(Motion);
			motion.friction = new Point(0,0);
			motion.maxVelocity = new Point(100,0);
			motion.minVelocity = new Point(0,0);
			motion.velocity = new Point(100,0);
			
			var boatMotion:Motion = new Motion();
			boatMotion.friction = new Point(0,0);
			boatMotion.maxVelocity = new Point(100,0);
			boatMotion.minVelocity = new Point(0,0);
			boatMotion.velocity = new Point(100,0);
			
			var ripplesMotion:Motion = new Motion();
			ripplesMotion.friction = new Point(0,0);
			ripplesMotion.maxVelocity = new Point(100,0);
			ripplesMotion.minVelocity = new Point(0,0);
			ripplesMotion.velocity = new Point(100,0);
			
			_ripples = new Entity();
			_ripples.add(new Display(super._hitContainer["ripples1"]));
			_ripples.add(new Spatial());
			_ripples.add(ripplesMotion);
			
			super.addEntity(_ripples);
			super.removeEntity(_ripples);
			
			_boat = new Entity();
			_boat.add(new Display(super._hitContainer["boat"]));
			_boat.add(new Spatial());
			_boat.add(boatMotion);
			_boat.add(new Boat(_boat, _boatHit, _ripples));
			var boatInteraction:Interaction = InteractionCreator.addToEntity(_boat, [InteractionCreator.DOWN]);
			//boatInteraction.down.add(onBoat);
			
			super.addEntity(_boat);
			
			_boat2 = new Entity();
			_boat2.add(new Display(super._hitContainer["boat2"]));
			_boat2.add(new Spatial());
			
			super.addEntity(_boat2);
			
			_loverBoy = super.getEntityById("loverBoy");
			_loverGirl = super.getEntityById("loverGirl");
			
			CharUtils.setDirection(_loverBoy, true);
			CharUtils.setDirection(_loverGirl, false);
		}
		
		private function initSounds():void{
			var entity:Entity = new Entity();
			var audio:Audio = new Audio();
			audio.play(SoundManager.EFFECTS_PATH + "gears_05b_L.mp3", true, [SoundModifier.POSITION, SoundModifier.MUSIC])
			entity.add(audio);
			entity.add(Spatial(_couple1.get(Spatial)));
			entity.add(new AudioRange(480, .01, 1.3, Quad.easeIn));
			entity.add(new Id("soundSource"));
			super.addEntity(entity);
			
			entity = new Entity();
			audio = new Audio();
			audio.play(SoundManager.EFFECTS_PATH + "gears_05b_L.mp3", true, [SoundModifier.POSITION, SoundModifier.MUSIC])
			entity.add(audio);
			entity.add(Spatial(_couple2.get(Spatial)));
			entity.add(new AudioRange(480, .01, 1.3, Quad.easeIn));
			entity.add(new Id("soundSource2"));
			super.addEntity(entity);
			
			entity = new Entity();
			audio = new Audio();
			audio.play(SoundManager.EFFECTS_PATH + "gears_05b_L.mp3", true, [SoundModifier.POSITION, SoundModifier.MUSIC])
			entity.add(audio);
			entity.add(Spatial(_couple3.get(Spatial)));
			entity.add(new AudioRange(480, .01, 1.3, Quad.easeIn));
			entity.add(new Id("soundSource3"));
			super.addEntity(entity);
			
			entity = new Entity();
			audio = new Audio();
			audio.play(SoundManager.EFFECTS_PATH + "gears_05b_L.mp3", true, [SoundModifier.POSITION, SoundModifier.MUSIC])
			entity.add(audio);
			entity.add(Spatial(_couple4.get(Spatial)));
			entity.add(new AudioRange(480, .01, 1.3, Quad.easeIn));
			entity.add(new Id("soundSource4"));
			super.addEntity(entity);
			
			entity = new Entity();
			boatAudio = new Audio();
			boatAudio.play(SoundManager.EFFECTS_PATH + "paddle_boat_loop.mp3", true, [SoundModifier.POSITION, SoundModifier.POSITION])
			entity.add(boatAudio);
			entity.add(Spatial(_boat.get(Spatial)));
			entity.add(new AudioRange(430, .01, 0.5, Quad.easeIn));
			entity.add(new Id("soundSource5"));
			super.addEntity(entity);
		}
		
		public function fadeOutBoatSound():void{
			if(!fading){
				_checkYuck = true;
				boatAudio.fadeAll(0.01);
				fading = true;
			}
		}
		
		private function initSystems():void
		{
			super.addSystem(new MotionSystem(), SystemPriorities.move);
			super.addSystem(new TimelineControlSystem());
			super.addSystem(new TimelineClipSystem());
			super.addSystem(new BoatSystem(super._hitContainer, this, _events));
		}
		
		private function initZones():void
		{
			var entity1:Entity = super.getEntityById("zone1");
			var zone1:Zone = entity1.get(Zone);
			zone1.pointHit = true;
			
			var entity2:Entity = super.getEntityById("zone2");
			var zone2:Zone = entity2.get(Zone);
			zone2.pointHit = true;
			
			var entity3:Entity = super.getEntityById("zone3");
			var zone3:Zone = entity3.get(Zone);
			zone3.pointHit = true;
			
			var entity4:Entity = super.getEntityById("zone4");
			var zone4:Zone = entity4.get(Zone);
			zone4.pointHit = true;
			
			var entity5:Entity = super.getEntityById("zoneExitRight");
			var zone5:Zone = entity5.get(Zone);
			zone5.pointHit = true;
			
			zone1.inside.add(handleZoneInside);
			zone2.inside.add(handleZoneInside);
			zone3.inside.add(handleZoneInside);
			zone4.inside.add(handleZoneInside);
			zone5.inside.add(handleZoneInside);
			
			if(super.shellApi.checkEvent(_events.TEENS_IN_TUNNEL) && !super.shellApi.checkEvent(_events.TEENS_FRIGHTENED)){
				zone3.entered.addOnce(startTeensSequence);
			}
		}
		
		private function setDoors():void
		{
			if(super.shellApi.checkEvent(_events.SET_NIGHT)){
				var doorEntityLeft:Entity = super.getEntityById("doorRidesLeft");
				Door(doorEntityLeft.get(Door)).data.destinationScene = "game.scenes.carnival.ridesNight.RidesNight";
				
				var doorEntityRight:Entity = super.getEntityById("doorRidesRight");
				Door(doorEntityRight.get(Door)).data.destinationScene = "game.scenes.carnival.ridesNight.RidesNight";
			}
		}
		
		private function startTeensSequence(zoneId:String, characterId:String):void
		{
			SceneUtil.lockInput(this, true);
			// start sequence
			teensMakeOut();
			SceneUtil.setCameraTarget(this, _loverBoy);
			// put in timer to start the teen dialog
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, startTeensDialog));
		}
		
		private function startTeensDialog():void{
			CharUtils.setAnim( _loverBoy, Stand);
			Dialog(_loverBoy.get(Dialog)).start.addOnce(faceLoverBoy);
			Dialog(_loverBoy.get(Dialog)).sayById("bestRide");
			//CharUtils.setAnim( _loverGirl, Laugh);
		}
		
		private function faceLoverBoy(dialogData:DialogData):void
		{
			CharUtils.setDirection(_loverBoy, true);
		}
		
		private function popOut():void{
			SceneUtil.lockInput(this, true);
			CharUtils.moveToTarget(super.player, 2842, 690, false, scareTeens);
		}
		
		private function scareTeens($entity:Entity):void{
			SceneUtil.setCameraTarget(this, super.player);
			CharUtils.setDirection(super.player, false);
			CharUtils.setAnim( super.player, Grief);
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, teensReact));
			CharUtils.setDirection(_loverBoy, true);
			CharUtils.setDirection(_loverGirl, true);
		}
		
		private function teensReact():void{
			// check if wearing mask or not
			var skinPart:SkinPart = SkinUtils.getSkinPart(super.player, SkinUtils.FACIAL);
			if(skinPart.value != "mc_fly_mask"){
				Dialog(_loverBoy.get(Dialog)).sayById("busyHere");
			} else {
				Dialog(_loverGirl.get(Dialog)).sayById("girlSqueal");
				CharUtils.setAnim( _loverGirl, Grief);
				CharUtils.setAnim( _loverBoy, Tremble);
				_teensScaredOff = true;
			}
		}
		
		private function teensRun():void{
			CharUtils.moveToTarget(_loverBoy, 3500, 800, false, teensOut);
			CharUtils.moveToTarget(_loverGirl, 3500, 800, false);
		}
		
		private function teensOut($entity:Entity):void
		{
			SceneUtil.lockInput(this, false);
			super.shellApi.completeEvent(_events.TEENS_FRIGHTENED);
			Display(_loverBoy.get(Display)).visible = false;
			Display(_loverGirl.get(Display)).visible = false;
			//super.removeEntity(_loverBoy);
			//super.removeEntity(_loverGirl);
		}
		
		private function teensMakeOut($loop:Boolean = false):void{
			// have teens do animations that appear they are .. ugh.. u know (Cabbage animation just looks WRONG btw!)
			CharUtils.setAnim( _loverBoy, KissStart);
			CharUtils.setAnim( _loverGirl, KissStart);
			// have heart particle effect over them - will add this if we have time for polish, but the animation seems pretty taxing on performance
		}
		
		private function handleZoneInside(zoneId:String, characterId:String):void
		{
			switch(zoneId)
			{
				case "zone1":
					Timeline(_couple1.get(Timeline)).play();
					break;
				case "zone2":
					Timeline(_couple2.get(Timeline)).play();
					break;
				case "zone3":
					Timeline(_couple3.get(Timeline)).play();
					break;
				case "zone4":
					Timeline(_couple4.get(Timeline)).play();
					break;
				case "zoneExitRight":
					exitScene();
					break;
			}
		}
		
		private function setDepths():void
		{
			super._hitContainer.swapChildren(Display(super.player.get(Display)).displayObject, Display(_boat.get(Display)).displayObject);
			super._hitContainer.setChildIndex(Display(_boat2.get(Display)).displayObject,super._hitContainer.numChildren - 1);
			super._hitContainer.setChildIndex(Display(_beads2.get(Display)).displayObject,super._hitContainer.numChildren - 1);
			super._hitContainer.setChildIndex(Display(_beads4.get(Display)).displayObject,super._hitContainer.numChildren - 1);
		}
		
		private function onBoat($entity:Entity):void
		{
			// if on platform, have player go through
			var platformCol:PlatformCollider = super.player.get(PlatformCollider);
			platformCol.ignoreNextHit = true;
			
			// have player jump onto boat
			CharUtils.moveToTarget(super.player, Spatial(_boatHit.get(Spatial)).x + 85, Spatial(_boatHit.get(Spatial)).y-38, false, gotOnBoat);
		}
		
		private function gotOnBoat($entity:Entity):void{
			CharUtils.setDirection(super.player, true);
		}
		
		public function moveBeads($rearSet:Boolean = false):void{
			if(!$rearSet){
				if(!_beads1played){
					super.shellApi.triggerEvent("beads");
					Timeline(_beads1.get(Timeline)).play();
					Timeline(_beads2.get(Timeline)).play();
					_beads1played = true;
				}
			} else {
				if(!_beads2played){
					super.shellApi.triggerEvent("beads");
					Timeline(_beads3.get(Timeline)).play();
					Timeline(_beads4.get(Timeline)).play();
					_beads2played = true;
				}
			}
		}
		
		public function putOnFlyMask():void{
			if(_notScared && !super.shellApi.checkEvent(_events.TEENS_FRIGHTENED)){
				// run back to scare point and repeat scaring process (this time with mask)
				popOut();
			}
		}
		
		public function fellInWater():void{
			if(!_checkYuck){
				_checkYuck = true;
				if(!super.shellApi.checkEvent(_events.FELL_IN_WATER)){
					Dialog(super.player.get(Dialog)).sayById("yuck");
				}
			}
		}
		
		private function exitScene($exitRight:Boolean = true):void{
			if(!_exitting){
				_exitting = true;
				if($exitRight){
					if(super.shellApi.checkEvent(_events.SET_NIGHT)){
						super.shellApi.loadScene(game.scenes.carnival.ridesNight.RidesNight, 4710, 1695);
					} else {
						super.shellApi.loadScene(game.scenes.carnival.ridesEvening.RidesEvening, 4710, 1695);
					}
				} else {
					if(super.shellApi.checkEvent(_events.SET_NIGHT)){
						super.shellApi.loadScene(game.scenes.carnival.ridesNight.RidesNight, 2740, 1695);
					} else {
						// force right exit if just scared teens (So you don't miss dialog)
						if(!_teensScaredOff){
							super.shellApi.loadScene(game.scenes.carnival.ridesEvening.RidesEvening, 2740, 1695); // normal
						} else {
							super.shellApi.loadScene(game.scenes.carnival.ridesEvening.RidesEvening, 4710, 1695); // after scaring teens
						}
					}
				}
			}
		}
		
		// ----------- HANDLERS ---------------
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			switch(event){
				case "popPlayer":
					popOut(); // jump out and scare teens
					teensMakeOut();
					break;
				case "loversNotScared":
					_notScared = true;
					SceneUtil.lockInput(this, false);
					CharUtils.setDirection(_loverGirl, false);
					teensMakeOut();
					break;
				case "loversRun":
					teensRun();
					break;
				case "flyMaskOn":
					putOnFlyMask();
					break;
			}
		}
		
		// animated scene parts
		private var _beads1:Entity;
		private var _beads2:Entity;
		private var _beads3:Entity;
		private var _beads4:Entity;
		
		private var _beads1played:Boolean = false;
		private var _beads2played:Boolean = false;
		
		private var _couple1:Entity;
		private var _couple2:Entity;
		private var _couple3:Entity;
		private var _couple4:Entity;
		
		private var _boat:Entity;
		private var _boatHit:Entity;
		
		private var _ripples:Entity;
		
		private var _boat2:Entity;
		
		private var _loverBoy:Entity;
		private var _loverGirl:Entity;
		
		private var _events:CarnivalEvents;
		
		private var _exitting:Boolean = false;
		
		private var _maskOn:Boolean = false;
		private var _checkYuck:Boolean = false;
		private var _notScared:Boolean = false;
		
		private var fading:Boolean = false;
		public var boatAudio:Audio;
		private var _teensScaredOff:Boolean;
		
	}
}